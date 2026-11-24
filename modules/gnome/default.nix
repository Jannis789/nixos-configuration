{ lib, ... }:
{
  imports = [
    ./dock.nix
    ./extensions.nix
  ];

  # Animationen aus: größter Einzelgewinn für gefühlte Responsiveness über
  # RDP/Selkies (jede Shell-Animation ist ein zusätzlicher Frame-Burst über
  # die Leitung). PoC 2026-11-24.
  dconf.settings."org/gnome/desktop/interface" = {
    enable-animations = false;
  };

  dconf.settings."org/gnome/settings-daemon/plugins/power" = {
    sleep-inactive-ac-type = "nothing";
    sleep-inactive-battery-type = "nothing";
  };

  # Kein Bildschirmschoner-Lock (2026-11-24): der Lockscreen schaltet den
  # Session-Mode auf "unlock-dialog" (allowScreencast=false), gnome-shell
  # ruft dann inhibit_remote_access() und mutter lehnt JEDE neue
  # ScreenCast-/RemoteDesktop-Session ab ("Session creation inhibited",
  # meta-dbus-session-manager.c) — Sunshine bekommt null Frames. Beobachtet
  # beim Bau dieser Lösung: der Inhibit-Zähler bleibt danach sogar nach dem
  # Entsperren hängen (nur ein Lock/Unlock-Zyklus oder ein Re-Login räumt
  # ihn auf). Für "nach Reboot ohne Login nutzbar" muss der Desktop also
  # unversperrt bleiben:
  #   * lock-enabled = false       → kein Lock beim Blanken
  #   * idle-activation-enabled    → kein automatisches Aktivieren
  #   * idle-delay = 0             → Bildschirm blankt gar nicht erst
  # Konsequenz: der physische Monitor zeigt die Session immer im Klartext.
  # Manuelles Sperren beendet den Stream (bewusster Trade-off).
  dconf.settings."org/gnome/desktop/screensaver" = {
    lock-enabled = false;
    idle-activation-enabled = false;
  };

  dconf.settings."org/gnome/desktop/session" = {
    idle-delay = lib.mkForce (lib.gvariant.mkUint32 0);
  };

  # RDP-Freigabe AUS (2026-11-24): mutter erlaubt genau EINE
  # RemoteDesktop-Session pro Sitzung. gnome-remote-deskop (User-Daemon)
  # belegt sie ab dem Login — Sunshines Portal-Capture scheitert dann mit
  # "Failed to create remote desktop session: Session creation inhibited"
  # (verifiziert: gdbus CreateSession auf org.gnome.Mutter.RemoteDesktop
  # schlug fehl, solange gvd lief, und funktionierte sofort nach
  # `systemctl --user disable --now gnome-remote-desktop`).
  # Adaptive Auflösung macht jetzt sunshine-display-mode (siehe
  # modules/host/sunshine.nix); der virtuelle gvd-Monitor (extend) wird
  # dafür nicht mehr gebraucht. Wer RDP/VNC zurückwill: hier wieder true
  # setzen UND sunshine abschalten — parallel geht nicht.
  dconf.settings."org/gnome/desktop/remote-desktop/rdp" = {
    enable = false;
    screen-share-mode = "extend";
  };

  # VNC-Freigabe ebenfalls aus (gleicher Grund wie oben). Das VNC-Backend
  # wird über das Overlay "grd-vnc" (overlays.nix) einkompiliert; das
  # Passwort läge im GNOME-Keyring (`grdctl vnc set-password`).
  dconf.settings."org/gnome/desktop/remote-desktop/vnc" = {
    enable = false;
    view-only = false;
    auth-method = "password";
  };
}
