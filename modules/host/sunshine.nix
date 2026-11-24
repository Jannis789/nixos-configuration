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
#   3. adaptive Auflösung → global_prep_cmd → sunshine-display-mode apply
#      setzt den primären Monitor auf den Modus, der der Client-Auflösung
#      am nächsten kommt (der XZ342CU bietet 720p … 3440x1440@165 und 4K
#      nativ an); `restore` beim Trennen stellt das alte Layout wieder her.
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
  lib,
  pkgs,
  ...
}:
let
  displayMode = pkgs.callPackage ../../packages/sunshine-display-mode.nix { };

  # Sollzustand des Schreibtischs. Wird gebraucht, weil mutter in
  # GetCurrentState seit 47 den aktiven Modus NICHT mehr meldet (nur
  # Connector/Vendor/Product/Serial) — ohne dieses Profil könnte `restore`
  # nur raten, worauf DP-3 vor dem Stream stand. Bei Monitorwechsel hier
  # anpassen (Format: CONNECTOR=BREITExHÖHE@HZ, kommasepariert).
  deskProfile = "DP-3=3440x1440@165,HDMI-1=2560x1440@144";

  # JSON, so wie Sunshine es in sunshine.conf erwartet. Das Skript liest die
  # Client-Auflösung selbst aus der Umgebung — Sunshine setzt
  # SUNSHINE_CLIENT_WIDTH/HEIGHT/FPS für prep-Commands (src/process.cpp).
  prepCommands = builtins.toJSON [
    {
      do = "${displayMode}/bin/sunshine-display-mode apply ${deskProfile}";
      undo = "${displayMode}/bin/sunshine-display-mode restore";
    }
  ];
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

      # KEIN global_prep_cmd mehr: mit dem virtuellen Monitor wird am
      # physischen Schreibtisch nichts mehr umgebaut (kein Monitor wird
      # ausgeblendet, kein Modus verbogen). Die Größe des Streams kommt
      # aus dem virtuellen Ausgang selbst — Sunshine übernimmt die
      # `size`-Property der Portal-Antwort (portalgrab.cpp).
      #
      # Nur für den Notausgang capture = "kms" wieder aktivieren:
      # global_prep_cmd = prepCommands;
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
  environment.systemPackages = [ displayMode ];
}
