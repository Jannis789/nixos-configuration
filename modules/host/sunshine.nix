# Sunshine + Moonlight — die EINE Streaming-Lösung für diesen Host.
#
# Warum Sunshine und nicht Selkies (modules/host/selkies.nix)?
# Selkies kann zwei der drei Anforderungen nicht erfüllen:
#   * adaptive Auflösung: der Portal-Capture hängt an der Host-Auflösung
#     (3440x1440), Resize-Requests sind auf GNOME ein No-Op;
#   * das Bild läuft als H.264 über WebSocket/TCP — Head-of-Line-Blocking,
#     kein adaptiver Bitrate-Regler, kein UDP.
# Sunshine liefert beides über Moonlight: UDP-Transport mit eigenem
# Congestion-Control, Hardware-Encode via VA-API und — über das
# DisplayConfig-Skript unten — echte Auflösungs-Anpassung an den Client.
#
# Anforderungen (Stand 2026-11-24):
#   1. nach Reboot ohne Login nutzbar → Autologin + Sunshine-User-Service
#      auf graphical-session.target (siehe unten, inkl. Lock-Warnung).
#   2. geringe Latenz → UDP + VA-API/H.264 (radeonsi), Animationen aus
#      (modules/gnome).
#   3. adaptive Auflösung → global_prep_cmd schreibt die Client-Auflösung
#      nach ~/.config/sunshine/virtual_monitor_size; das gepatchte
#      xdg-desktop-portal-gnome legt den virtuellen Monitor genau in dieser
#      Größe an (RecordVirtual → modes → preferred mode in mutter 51).
#      Der Stream läuft damit in Client-Auflösung, unabhängig davon,
#      welche Modi die physischen Monitore anbieten.
#
# Capture-Pfad: `capture = portal` — auf GNOME ist das der einzige Weg:
#   * wlr/wlgrab  → braucht zwlr_screencopy_v1, hat mutter nicht
#   * kwin        → braucht KDE-Screencast, hat mutter nicht
#   * kms         → bräuchte CAP_SYS_ADMIN, und mutter ist DRM-Master
#   * portal      → xdg-desktop-portal-gnome + PipeWire, hängt sich als
#                   Client an die laufende Session (wie gnome-remote-desktop)
# Input läuft dabei über die RemoteDesktop-Portal-Session (Tastatur/Maus)
# bzw. uinput für Gamepads (`hardware.uinput.enable` setzt das Modul).
#
# EINMALIGE AKTION beim ersten Verbinden: der Portal-Dialog ("Bildschirm
# teilen" + "Fernsteuerung erlauben") muss am physischen Monitor bestätigt
# werden. Sunshine sichert sich dabei einen persistierenden Restore-Token
# (persist_mode = UNTIL_REVOKED, Datei unter ~/.config/sunshine/), danach
# kommt der Stream ohne Dialog hoch — auch nach einem Reboot.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  displayMode = pkgs.callPackage ../../packages/sunshine-display-mode.nix { };

  # Sollzustand des Schreibtischs (nur noch für den Notausgang
  # capture = "kms" relevant — mit dem virtuellen Monitor wird am
  # physischen Layout nichts mehr umgebaut).
  deskProfile = "DP-3=3440x1440@165,HDMI-1=2560x1440@144";

  # Übergibt die Client-Auflösung an das gepatchte
  # xdg-desktop-portal-gnome (overlays.nix: xdg-desktop-portal-gnome-virtual).
  # Sunshine ruft Prep-Commands VOR dem Aufbau der Capture-Session auf und
  # setzt in der Umgebung SUNSHINE_CLIENT_WIDTH/HEIGHT/FPS
  # (src/process.cpp). Das Portal-Backend liest daraus den preferred mode
  # für den virtuellen Monitor (Format BREITExHÖHE@HZ).
  virtualMonitor = pkgs.writeShellScript "sunshine-virtual-monitor" ''
    set -eu
    confdir="''${XDG_CONFIG_HOME:-$HOME/.config}/sunshine"
    case "''${1:-}" in
      set)
        mkdir -p "$confdir"
        width="''${SUNSHINE_CLIENT_WIDTH:-0}"
        height="''${SUNSHINE_CLIENT_HEIGHT:-0}"
        fps="''${SUNSHINE_CLIENT_FPS:-60}"
        if [ "$width" -gt 0 ] && [ "$height" -gt 0 ]; then
          printf '%sx%s@%s\n' "$width" "$height" "$fps" > "$confdir/virtual_monitor_size"
        fi
        ;;
      clear)
        rm -f "$confdir/virtual_monitor_size"
        ;;
    esac
  '';

  # JSON, so wie Sunshine es in sunshine.conf erwartet.
  prepCommands = builtins.toJSON [
    {
      # Client-Auflösung für den virtuellen Monitor hinterlegen.
      do = "${virtualMonitor} set";
      undo = "${virtualMonitor} clear";
    }
    # AUSKOMMENTIERT (2026-11-24): `watch` hat das Live-Layout des
    # Schreibtischs umgebaut (virtueller Monitor als einziger Monitor).
    # Ergebnis: gnome-shell ist beim Drehen eines physischen Monitors mit
    # SIGSEGV abgestürzt, und die Umstellung bringt mehr Risiko als Nutzen.
    # Ohne diesen Schritt ist der virtuelle Monitor eine reine ERWEITERUNG
    # des Desktops — kein Panel, keine Fenster, aber auch kein Eingriff in
    # die physische Anzeige. Der saubere Weg ist eine eigene headless
    # GNOME-Session (siehe Notiz unten), nicht ein Umbau der laufenden.
    # {
    #   do = "${displayMode}/bin/sunshine-display-mode watch";
    #   undo = "${displayMode}/bin/sunshine-display-mode restore";
    # }
  ];

  # Dieselbe sunshine.conf, die das NixOS-Modul rendert (eine Quelle:
  # services.sunshine.settings). Der headless-Dienst startet Sunshine mit
  # dieser Datei ausdrücklich, weil er den ExecStart des Moduls ersetzt.
  configFile = (pkgs.formats.keyValue { }).generate "sunshine.conf" config.services.sunshine.settings;

  # Startet EINE komplette, unsichtbare GNOME-Session und darin Sunshine.
  # Das Skript läuft als User-Unit im Manager von jannis (dieselbe UID wie
  # der physische Schreibtisch), aber in einem eigenen dbus-run-session-Bus:
  #   gnome-shell (headless)  ->  xdg-desktop-portal-gnome + -portal  ->  sunshine
  # Vorteile gegenüber "virtueller Monitor in der laufenden Session":
  #   * der virtuelle Monitor ist hier der EINZIGE Monitor, also liegen
  #     Panel, Fenster und Übersicht im Stream (kein "nur Erweiterung");
  #   * das physische Layout (Rotation des 27", Primärmonitor) wird nicht
  #     angefasst - kein ApplyMonitorsConfig auf der Live-Session, was
  #     gnome-shell schon einmal mit SIGSEGV quittiert hat;
  #   * mit Linger läuft die Session schon beim Boot, ohne Login.
  headlessSession = pkgs.writeShellScript "sunshine-headless-session" ''
    set -eu

    # Portal-Konfiguration (gnome.portal, gnome-portals.conf) und GNOME-
    # Schemata vor die geerbten Pfade legen (siehe portalDataDirs oben).
    export XDG_DATA_DIRS="${portalDataDirs}''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"

    # Verteidigungslinie: sollte die Unit doch einmal aus einer Sitzung mit
    # Anzeige gestartet werden (manuell, alter Stand), sind diese Namen
    # falsch. Unser Compositor legt seine eigenen an — mutter setzt die
    # richtigen Werte selbst, wir ermitteln sie unten über seine Sockets.
    unset WAYLAND_DISPLAY DISPLAY XAUTHORITY GNOME_SETUP_DISPLAY XDG_SESSION_ID

    # Zeitmarke: daran erkennen wir später, welche Dateien (z. B. die
    # Xwayland-Auth-Datei) zu DIESER Session gehören.
    marker="$XDG_RUNTIME_DIR/.sunshine-headless-start"
    touch "$marker"

    # 1) Compositor (mutter headless-Backend, kein DRM-Gerät, keine Seat).
    ${pkgs.gnome-shell}/bin/gnome-shell --headless &
    shell_pid=$!
    trap 'kill "$shell_pid" 2>/dev/null || true' EXIT

    busctl="${pkgs.systemd}/bin/busctl"

    # Wartet, bis ein Name auf DIESEM (privaten) Bus existiert.
    wait_for() {
      i=0
      while [ "$i" -lt 120 ]; do
        if "$busctl" --user status "$1" >/dev/null 2>&1; then
          echo "bereit: $1"
          return 0
        fi
        if ! kill -0 "$shell_pid" 2>/dev/null; then
          echo "gnome-shell ist beendet - Abbruch" >&2
          return 1
        fi
        sleep 0.5
        i=$((i + 1))
      done
      echo "Timeout beim Warten auf $1" >&2
      return 1
    }

    wait_for org.gnome.Mutter.ScreenCast

    # 2) Anzeige-Namen der headless-Session in die D-Bus-Aktivierungsumgebung
    # heben. D-Bus-aktivierte Apps (Nautilus, Console, Text Editor,
    # Einstellungen ...) startet der Bus-Daemon, sie erben dessen
    # Environment — nicht das der Shell. Ohne diesen Schritt bekommen sie
    # WAYLAND_DISPLAY=wayland-0 (physischer Schreibtisch) bzw. starten nicht.
    # /proc/<pid>/environ zeigt nur den Stand beim exec; mutter setzt
    # WAYLAND_DISPLAY/DISPLAY erst zur Laufzeit (set_gnome_env). Deshalb über
    # die offenen Sockets des Compositors fragen.
    sockets="$(ss -xlp 2>/dev/null | grep "pid=$shell_pid," || true)"

    wl_path="$(printf '%s\n' "$sockets" | grep -o '/run/user/[0-9]*/wayland-[0-9]*' | head -1)"
    if [ -n "$wl_path" ]; then
      export WAYLAND_DISPLAY=''${wl_path##*/}
    fi

    # Die öffentliche Xwayland-Anzeige hat die kleinere Nummer; die andere ist
    # GNOME_SETUP_DISPLAY.
    x_num="$(printf '%s\n' "$sockets" | grep -o '/tmp/.X11-unix/X[0-9]*' | sed 's#.*/X##' | sort -n | head -1)"
    if [ -n "$x_num" ]; then
      export DISPLAY=":$x_num"
    fi

    xauth="$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name '.mutter-Xwaylandauth.*' -newer "$marker" 2>/dev/null | head -1)"
    if [ -n "$xauth" ]; then
      export XAUTHORITY="$xauth"
    fi

    ${pkgs.dbus}/bin/dbus-update-activation-environment --all || true
    echo "headless display: WAYLAND_DISPLAY=''${WAYLAND_DISPLAY:-?} DISPLAY=''${DISPLAY:-?} XAUTHORITY=''${XAUTHORITY:-?}"

    # 2) Portal-Backend (gepatcht: virtuelle Stream-Größe = Client-Größe,
    #    kein Consent-Dialog) und Frontend im selben Bus. Beide müssen hier
    #    laufen: das Frontend cached die Fähigkeiten des Backends
    #    (available-cursor-modes) und lehnt sonst jede Anfrage ab.
    ${pkgs.xdg-desktop-portal-gnome}/libexec/xdg-desktop-portal-gnome &

    # WICHTIG: erst warten, bis das Backend seinen Busnamen hat. Das Frontend
    # legt beim Start einen GDBusProxy auf org.freedesktop.impl.portal.desktop.
    # gnome an und liest dessen Properties (available-source-types,
    # available-cursor-modes). Ist der Name noch frei, sind die Properties 0
    # und das Frontend lehnt danach JEDE ScreenCast-Anfrage ab
    # ("Unavailable cursor mode 2").
    wait_for org.freedesktop.impl.portal.desktop.gnome

    ${pkgs.xdg-desktop-portal}/libexec/xdg-desktop-portal &

    wait_for org.freedesktop.portal.Desktop

    # 3) Sunshine übernimmt den Prozess (exec), damit systemd den Zustand
    #    korrekt sieht. capture=portal spricht jetzt mit dem Portal DIESER
    #    Session: der Stream zeigt die headless-Session.
    # 4) Portal-Restore-Token wegwerfen. Er verweist auf eine ScreenCast-
    #    Session einer FRUEHEREN mutter-Instanz; nach einem Reboot haengt
    #    CreateSession damit (2026-11-25 beobachtet: Dienst "active", aber
    #    Sunshine oeffnete nie 47989/47984/48010 -> moonlight-web meldet
    #    "couldn't establish a connection"/HostNotFound, es laesst sich
    #    keine Session mehr starten). Der Token spart nur den Consent-
    #    Dialog - den umgeht der Portal-Patch fuer VIRTUAL ohnehin.
    #    Kostet nichts und macht den Boot deterministisch.
    rm -f "''${XDG_CONFIG_HOME:-$HOME/.config}/sunshine/portal_token"

    exec ${pkgs.sunshine}/bin/sunshine ${configFile}
  '';

  # Environment des Dienstes: eigene GNOME-Session, eigene Anzeige.
  headlessEnv = {
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "gnome";
    XDG_CURRENT_DESKTOP = "GNOME";
    GNOME_SHELL_SESSION_MODE = "user";

    # Tastatur/Maus über org.gnome.Mutter.RemoteDesktop einspeisen
    # (src/platform/virtualhid_input.cpp, patches/sunshine-mutter-input.patch).
    # libvirtualhid legt sonst kernelweite uinput-Geräte an, die am
    # physischen Seat landen — die headless-Session hat keinen Seat.
    SUNSHINE_GNOME_REMOTE_DESKTOP_INPUT = "1";
  };

  # Zusätzliche XDG_DATA_DIRS VOR die vom User-Manager geerbten setzen (im
  # Skript, nicht hier: der Manager liefert u. a. die nixos-mimeapps- und
  # desktops-Pakete, die dürfen nicht verloren gehen). Ohne diese Pfade
  # findet das Portal seine Backend-Konfiguration (gnome-portals.conf,
  # gnome.portal) und GNOME seine GSettings-Schemata nicht.
  portalDataDirs = lib.concatStringsSep ":" [
    "${pkgs.xdg-desktop-portal-gnome}/share"
    "${pkgs.gnome-session}/share"
    "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/gsettings-desktop-schemas"
    "${pkgs.gnome-shell}/share"
  ];
  # Eigner Profil-Ordner fuer die Chromium-Familie (siehe Modul-Body):
  # sonst verweigert der zweite Start "Profil wird bereits verwendet".
  streamHelium = pkgs.writeShellScriptBin "stream-helium" ''
    exec ${pkgs.helium}/bin/helium \
      --user-data-dir="''${XDG_CONFIG_HOME:-$HOME/.config}/sunshine/stream-helium" \
      "$@"
  '';
  streamHeliumDesktop = pkgs.runCommand "stream-helium-desktop" { } ''
    mkdir -p $out/share/applications
    cat > $out/share/applications/stream-helium.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=Helium (Stream-Profil)
    Comment=Helium mit eigenem Profil — parallel zum Desktop startbar
    Exec=${streamHelium}/bin/stream-helium %U
    Icon=helium
    Categories=Network;WebBrowser;
    Terminal=false
    EOF
  '';
in
{
  services.sunshine = {
    enable = true;

    # 47984-47990/tcp + 47998-48010/udp (Ports werden von `port` abgeleitet).
    # BEWUSST AUS: Sunshine wird ausschließlich lokal angesprochen —
    # moonlight-web (Pairing/RTSP/RTP) und das Web-UI über nginx
    # (/sunshine/, hinter Authelia). Ein offener Port 47990 im Internet wäre
    # eine Admin-Oberfläche ohne 2FA gewesen (genau der 403-Fall von
    # 2026-11-24). Wer einen NATIVEN Moonlight-Client im LAN nutzen will,
    # braucht diese Ports — dann hier gezielt wieder aktivieren.
    openFirewall = false;

    # Nur für KMS-Capture nötig: /dev/dri liest fremde Frames nur mit
    # CAP_SYS_ADMIN (drmPrimeHandleToFD auf Handles des Compositors). Das
    # NixOS-Modul baut dafür einen setcap-Wrapper ($wrapperDir/sunshine)
    # und startet den Dienst darüber — kein root-Dienst, nur die Capability
    # am Binary.
    capSysAdmin = true;

    settings = {
      sunshine_name = "jannis-desktop";
      port = 47989;

      # Capture über das Portal, aber mit einem VIRTUELLEN Monitor:
      # Sunshine fragt in ScreenCast.SelectSources types=VIRTUAL (4) statt
      # types=MONITOR (1) an — das erledigt das Overlay `sunshine-virtual`
      # (overlays.nix, postPatch auf src/platform/linux/portalgrab.cpp).
      # mutter legt daraufhin einen zusätzlichen, unsichtbaren Monitor an,
      # der von den physischen Ausgängen, ihren Modi und ihrer EDID
      # unabhängig ist. Der Stream hängt damit nicht mehr an einem
      # Connector-Namen und nicht am Modus eines realen Monitors.
      #
      # Preis: beim allerersten Verbinden erscheint einmalig der
      # Portal-Dialog ("Bildschirm teilen") und muss am physischen Monitor
      # bestätigt werden. Danach wird die Session über den persistierenden
      # Restore-Token (persist_mode=UNTIL_REVOKED, Datei
      # ~/.config/sunshine/portal_token) dialogfrei wiederhergestellt —
      # auch nach einem Reboot.
      #
      # Notausgang: capture = "kms" (liest den DRM-Framebuffer direkt,
      # ohne Dialog, braucht cap_sys_admin und die DisplayConfig-Umbauten
      # aus prepCommands, siehe unten).
      capture = "portal";

      # AMD (radeonsi über mesa) → h264_vaapi. Fallback auf Software
      # (x264) macht Sunshine selbst, wenn VA-API nicht initialisiert.
      encoder = "vaapi";

      min_log_level = "info";

      # Kein Tray-Icon: durch die mkForce'd PATH-Umgebung des NixOS-Moduls
      # und den fehlenden StatusNotifier-Host (GNOME ohne AppIndicator-
      # Extension) scheitert die Tray-Initialisierung und Sunshine loggt
      # "Error: System tray is not initialized" und beendet seinen Main-Loop.
      system_tray = false;

      # Web-UI auch von außerhalb erreichbar (Default ist "lan"): von einer
      # WAN-IP antwortet Sunshine sonst mit 403 Forbidden — genau das trat
      # beim Aufruf von https://<host>:47990 aus dem Internet auf (im Log
      # steht dazu nur auf Debug-Level etwas, deshalb war nichts zu sehen).
      # Nur das Web-UI; Pairing bleibt über moonlight-web lokal (127.0.0.1).
      # Nach dem Einrichten des Passworts Port 47990 im Router wieder
      # schließen und per SSH-Tunnel zugreifen.
      origin_web_ui_allowed = "wan";

      # CSRF-Freigabe für den Proxy-Zugriff: der Browser schickt beim POST
      # (Passwort setzen, Pairing-PIN) "Origin: https://jannis.nix-dev.link",
      # Sunshine erwartet seine eigene Adresse und antwortet sonst mit
      # "CSRF protection blocked request from origin" (HTTP 500 im UI:
      # "Error! Internal Server Error"). Über nginx ist die öffentliche URL
      # die legitime Herkunft.
      csrf_allowed_origins = "https://jannis.nix-dev.link";

      # Prep-Command: schreibt die Client-Auflösung nach
      # ~/.config/sunshine/virtual_monitor_size, von wo das gepatchte
      # Portal-Backend sie beim Anlegen des virtuellen Monitors liest.
      # Damit kommt der virtuelle Monitor in exakt der Auflösung hoch, die
      # der Client angefragt hat — adaptive Auflösung ohne Umbau des
      # physischen Layouts.
      global_prep_cmd = prepCommands;
    };

    # Keine `applications` hier: solange kein apps.json gesetzt ist, kann man
    # Apps im Web-UI (https://jannis.nix-dev.link/sunshine/ → siehe unten)
    # bzw. direkt auf Port 47990 pflegen. global_prep_cmd greift für alle.
  };

  # --- Anforderung 1: nach Reboot ohne Login nutzbar ---
  # Autologin: der GDM-Greeter ist eine eigene Session und NICHT capturable,
  # deshalb muss die echte Session von selbst hochkommen.
  # (Identische Werte setzt modules/host/selkies.nix — harmlos, gleicher Wert.)
  #
  # WICHTIG, unverändert gültig (PoC 2026-11-24): NICHT nach dem Autologin
  # sperren. Der Lockscreen läuft im Session-Mode "unlock-dialog" mit
  # allowScreencast=false, gnome-shell ruft daraufhin
  # inhibit_remote_access() und mutter lehnt ScreenCast-/RemoteDesktop-
  # Sessions ab ("Session creation inhibited") — der Stream bliebe schwarz.
  # Reboot heißt hier also: unversperrter Desktop am physischen Monitor.
  services.displayManager.autoLogin = {
    enable = true;
    user = "jannis";
  };

  # Werkzeug auch in der interaktiven Shell haben (Debug/„Monitor zurück“).
  environment.systemPackages = [
    displayMode
    streamHelium
    streamHeliumDesktop
  ];

  # --- Programme, die pro Profil nur EINMAL laufen ------------------------
  # Die allermeisten GNOME-Apps sind D-Bus-Single-Instance. Weil die
  # Stream-Session einen EIGENEN Session-Bus hat, registriert dort eine
  # zweite Instanz und bekommt ihr Fenster im Stream — die laufende
  # Desktop-Instanz bleibt unangetastet. Nichts zu tun.
  #
  # Anders die Chromium-Familie: die prüft einen SingletonLock im
  # user-data-dir, unabhängig vom Bus. Zweiter Start = "Profil wird bereits
  # verwendet". Dafür ein eigenes Datenverzeichnis (eigenes Profil: Logins
  # müssen dort einmal gemacht werden). Der Wrapper steht im let-Block.
  #
  # Erscheint in der App-Übersicht (auch im Stream) als eigener Eintrag.

  # --- Eine eigene, unsichtbare GNOME-Session für den Stream ------------
  # Statt den virtuellen Monitor in die laufende Sitzung zu hängen (nur
  # eine Erweiterung: kein Panel, keine Fenster, und der Umbau des
  # Live-Layouts hat gnome-shell zum Absturz gebracht), läuft der Stream
  # in einer eigenen GNOME-Session im Account virtual-jannis:
  #   gnome-shell --headless → xdg-desktop-portal(-gnome) → sunshine
  # In dieser Session ist der virtuelle Monitor der einzige Monitor, also
  # liegen Panel/Fenster/Übersicht im Stream. Der physische Schreibtisch
  # (inkl. Rotation des 27") bleibt völlig unberührt.
  #
  # Eigener Account, weil pro UID genau ein systemd --user und ein dconf
  # existieren: im jannis-Manager gestartete Apps erbten dessen
  # WAYLAND_DISPLAY=wayland-0 und landeten auf dem physischen Schreibtisch,
  # und der Stream hätte das dconf/PermissionStore des Schreibtischs benutzt.
  #
  # Die Portal-Patches (overlays.nix / packages/patches) sorgen dafür, dass
  #   * der virtuelle Monitor in Client-Auflösung angelegt wird
  #     (RecordVirtual "modes" ← ~/.config/sunshine/virtual_monitor_size,
  #     Default 1920x1080@60),
  #   * der Consent-Dialog entfällt, wenn nur VIRTUAL angefragt wird —
  #     ohne diesen Bypass würde Start headless ewig hängen (der GTK-Dialog
  #     kann ohne Display nie beantwortet werden).
  #
  # Hier wird der ExecStart des NixOS-Moduls ersetzt (nicht ein zweiter
  # Dienst daneben gestellt), damit nur EINE Sunshine-Instanz läuft und die
  # gerenderte sunshine.conf (services.sunshine.settings) weiterhin die
  # einzige Konfigurationsquelle bleibt.
  #
  # Der Dienst läuft im Manager von jannis (Linger: startet beim Boot, ohne
  # Login) und umfasst NUR die headless-Session — der physische Schreibtisch
  # läuft in einer anderen Session derselben UID.
  systemd.user.services.sunshine = {
    description = lib.mkForce "Sunshine (headless GNOME-Session)";

    wantedBy = lib.mkForce [ "default.target" ];
    after = lib.mkForce [ ];
    wants = lib.mkForce [ ];
    partOf = lib.mkForce [ ];

    environment = headlessEnv // {
      # Das Modul setzt PATH mit mkForce auf null (Tray-Symbole). Das
      # Startskript braucht coreutils (sleep/touch), busctl, ss, find, grep
      # und dbus-update-activation-environment; mkOverride 40 gewinnt gegen
      # mkForce (Priorität 50).
      PATH = lib.mkOverride 40 (
        lib.concatStringsSep ":" [
          (lib.makeBinPath [
            pkgs.coreutils
            pkgs.systemd
            pkgs.dbus
            pkgs.iproute2
            pkgs.findutils
            pkgs.gnugrep
            pkgs.gnused
          ])
          "/etc/profiles/per-user/jannis/bin"
          "/run/current-system/bin"
          "/run/current-system/sw/bin"
        ]
      );
    };

    # NixOS-Benutzer-Units sind GLOBAL (/etc/systemd/user): wantedBy =
    # default.target startet sie in JEDEM User-Manager — auch im dynamischen
    # gdm-greeter-Account. Beim Boot 2026-11-25 lief dadurch eine ZWEITE
    # headless Session (gnome-shell-Coredump unter UID 60578 in
    # …/user@60578.service/app.slice/sunshine.service), die mit jannis'
    # Instanz um Port 48010 stritt ("Couldn't bind RTSP server … Address
    # already in use", gestern 20:37 und heute 07:48). Bedingung hält die
    # Unit auf den intendierten Account — derselbe wie beim Autologin.
    unitConfig = {
      ConditionUser = config.services.displayManager.autoLogin.user;
    };

    serviceConfig = {
      # dbus-run-session: DIESELBE UID wie der physische Schreibtisch, aber
      # ein eigener Session-Bus. Nur so können Apps zweimal laufen (Shell,
      # Nautilus, Einstellungen) und D-Bus-Aktivierung landet nicht auf
      # wayland-0. Genau dieses Muster beschreibt mutters
      # doc/building-and-running.md (dbus-session.sh new + gnome-shell
      # --headless) für eine zweite Sitzung derselben UID.
      ExecStart = lib.mkForce "${pkgs.dbus}/bin/dbus-run-session -- ${headlessSession}";
      # IMMER neu starten, nicht nur on-failure: Sunshine beendet sich auch
      # nach fatalen Startfehlern ("Unable to find display or encoder",
      # RTSP-Port belegt) mit Exit-Code 0. Beobachtet 2026-11-25: Boot-
      # Crash der headless gnome-shell → Result=success → on-failure
      # griff nie, der Dienst blieb stumm tot. "always" lässt die Unit
      # nach einem solchen Crash nach RestartSec selbst heilen.
      Restart = lib.mkForce "always";
      RestartSec = lib.mkForce 5;
    };
  };
}
