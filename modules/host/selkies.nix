# Selkies — Game-Streaming der ECHTEN GNOME-Wayland-Session in den Browser.
#
# Architektur:
#   Browser → https://jannis.nix-dev.link/stream/ → nginx (TLS + Authelia,
#   siehe nginx.nix) → WebSocket → Selkies-Userservice (127.0.0.1:8080,
#   alle Routen inkl. WebSocket/API/static unter dem Präfix /stream)
#
# Capture: pixelflux mit --wayland-host-display hängt sich als Client an
# die Session (wayland-0) und captured über xdg-desktop-portal/PipeWire
# zero-copy in den Encoder — dieselbe Maschinerie wie gnome-remote-desktop,
# nur mit WebSocket/H.264-Transport statt RDP. Input läuft über den
# RemoteDesktop-Portal-Pfad, Gamepads als echte Kernel-Geräte über
# /dev/uinput (deshalb Gruppe "input" für jannis, siehe users.nix).
# KEIN X11 irgendwo im Pfad; die Session bleibt Wayland.
#
# Login nach Reboot: Autologin statt "GDM streamen" (der Greeter ist eine
# eigene gdm-Session und nicht capturable). KEIN Lock danach — Details und
# Begründung beim AutoLogin-Block unten.
#
# ERLEDIGT (PoC 2026-11-24): Das Consent-Problem ist gelöst. pixelflux
# fragt über den ScreenCast-Portal ein persistierendes Einverständnis an
# und speichert den Restore-Token in
# ~/.local/state/pixelflux/portal-restore-token — einmal bestätigt (hier:
# 2026-11-23 am Bildschirm), kommt der Stream danach ohne Dialog hoch.
# Der eigentliche Stream-Killer war der Lockscreen, siehe unten.
#
# Fällt VA-API im AppImage-FHS flach, greift automatisch der x264-
# Software-Encoder (bei 1080p verkraftbar, aber im Stream-Log prüfen).
{
  lib,
  pkgs,
  ...
}:
let
  selkiesArgs = lib.concatStringsSep " " [
    "--wayland=true" # Master-Schalter Wayland-Backend (PoC 2026-11-23: ohne dies greift der X11-Fallback)
    "--wayland-host-display=wayland-0" # echte Session capturen, kein eigener Compositor
    "--port=8080"
    # Reverse-Proxy-Präfix: Selkies hängt ALLE Routen (WebSocket, Tokens,
    # Metrics, statischen Web-Client) an /stream — passend zur nginx-Location
    # /stream/, die den Pfad unverändert durchreicht. Der Client liest seinen
    # eigenen Präfix selbst aus der URL, nur der Server muss es wissen.
    "--subfolder=/stream"
    # DPI serverseitig pinnen: Clients drücken sonst bei JEDEM Verbinden ihr
    # eigenes DPI (Mac hier: 120) als "system-level change" auf den Desktop
    # und skalieren damit Monitor-Layout bzw. GNOME-UI um — Desktop-Schutz
    # für den physischen Monitor (Beobachtung 2026-11-24: Scale-Tänze
    # 2.0/1.25 im Log, Cursor-Offset im Fenstermodus). Einmal vom Operator
    # gesetzt, ist der
    # Wert für Clients GESPERRT — das Dashboard rendert ihn read-only
    # (settings.py: OPERATOR_LOCKED_WHEN_OVERRIDDEN).
    "--scaling_dpi=96"
    "--enable-https=false" # TLS terminiert der nginx
    "--enable-basic-auth=false" # Auth übernimmt Authelia am nginx
    # Resize-Requests der Clients durchlassen. EHRLICHE LAGE (PoC
    # 2026-11-24): Auf GNOME-Host-Capture ist das ein NO-OP — GNOME
    # implementiert zwlr_output_manager_v1 nicht und verweigert Layout-
    # Änderungen, der Stream bleibt in Monitor-Auflösung ("host refused
    # the layout; capture follows the host's own size"). Der Button
    # "manuelle Auflösung" im Dashboard resized nur die interne Fläche,
    # nicht den Encode. Trotz aktiviert: schadet hier nicht und greift
    # automatisch, falls der Capture-Pfad mal wechselt (interner
    # Compositor, KDE-Host). Anpassung ans Browser-Fenster macht in
    # diesem Modus der Client selbst (Letterbox-Skalierung).
    "--enable-resize=true"
    "--encoder=h264enc" # VA-API (Intel), Fallback: x264 software
  ];
in
{
  # --- Login nach Reboot: Autologin, OHNE Lock ---
  # Revertierbar: dieses Modul rausnehmen → kein Autologin mehr.
  # (desktop.nix setzt gdm.enable; hier bewusst nur der AutoLogin-Teil,
  # damit das ganze Feature in einer Datei lebt.)
  #
  # BEWUSST kein Lock-after-Autologin (PoC 2026-11-24 nachgestellt): Der
  # Lockscreen schaltet den gnome-shell-Session-Mode auf "unlock-dialog"
  # mit allowScreencast=false. main.js ruft daraufhin
  # remote_access_controller.inhibit_remote_access() auf — mutter lehnt
  # das Anlegen von RemoteDesktop- UND ScreenCast-Sessions ab
  # ("Session creation inhibited", meta-dbus-session-manager.c) und
  # schließt sogar LAUFENDE Sessions. pixelflux fällt dann auf seinen
  # leeren internen Compositor zurück: null Frames, die Seite bleibt bei
  # "waiting for stream". Das Passwort-im-Browser-Unlock funktioniert nur
  # mit gvd/RDP, nicht über den Portal-Pfad. Konsequenzen:
  #   * Reboot → unversperrter Desktop am physischen Monitor
  #   * Manuell sperren = Stream-Ende; Rettungsweg zum Entsperren ist
  #     gvd-RDP auf Port 3389 (remote-desktop.nix) — oder das Passwort
  #     blind über die uinput-Tastatur des Streams tippen und die Seite
  #     danach neu laden.
  # Wer physischen Schutz braucht, sperrt beim Verlassen des Schreibtischs.
  services.displayManager.autoLogin = {
    enable = true;
    user = "jannis";
  };

  # VA-API-Treiber für die Intel-iGPU: ohne ihn meldet pixelflux
  # "no VA driver initialized" und encodiert 3440x1440@60 in Software
  # (x264, 4 Threads) — der eigentliche Grund für die gefühlte Trägheit.
  # iHD (intel-media-driver) für Gen8+, i965 als Fallback für ältere.
  hardware.graphics.extraPackages = [
    pkgs.intel-media-driver
    pkgs.intel-vaapi-driver
  ];

  systemd.user.services.selkies = {
    description = "Selkies — Stream der GNOME-Wayland-Session (WebSocket :8080)";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    # Treiber explizit in die AppImage-FHS-Umgebung zeigen — appimage-run
    # reicht nicht automatisch alle libva-Treiber durch (PoC 2026-11-24).
    environment = {
      LIBVA_DRIVER_NAME = "radeonsi";
      LIBVA_DRIVERS_PATH = "${pkgs.mesa.drivers}/lib/dri";
    };
    # Portal-Capture kann in Ausnahmefällen sterben (abgelehnte Einwilligung,
    # Compositor-Restart) — dann neu versuchen statt aufgeben.
    serviceConfig = {
      ExecStartPre = ''
        ${pkgs.bash}/bin/bash -c 'until [ -e "$XDG_RUNTIME_DIR/wayland-0" ]; do ${pkgs.coreutils}/bin/sleep 1; done'
      '';
      # PoC 2026-11-23: DISPLAY per env -u entfernen — der User-Manager importiert
      # DISPLAY (:0 = XWayland) in die Unit, und pixelflux nimmt sonst X11 statt
      # des Wayland-Host-Displays. systemd kann Variablen nicht unsetten,
      # deshalb der env-Umweg.
      ExecStart = "${pkgs.coreutils}/bin/env -u DISPLAY ${pkgs.selkies}/bin/selkies ${selkiesArgs}";
      Restart = "on-failure";
      RestartSec = "5";
    };
  };
}
