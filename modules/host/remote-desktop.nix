# gnome-remote-desktop gibt es in zwei Varianten:
#
#  * System-Daemon ("Remote Login", RDP-Logins mit eigenen Sessions):
#    bindet Port 3389, Credentials via `sudo grdctl --system ...`
#    (Landen in /var/lib/gnome-remote-desktop). restartIfChanged=false,
#    damit laufende RDP-Sessions bei einem switch nicht gekillt werden —
#    nach GRD-Updates läuft deshalb bis zum Reboot die alte Binary.
#
#  * User-Daemon ("Desktop Sharing" der aktiven Session): wird über die
#    GNOME-Einstellungen bzw. grdctl aktiviert und legt dabei eine KOPIE
#    der Unit in ~/.config/systemd/user/ an — mit fest eingebautem
#    Store-Pfad. Nach GRD-Updates diese Kopie löschen und neu aufsetzen:
#      rm ~/.config/systemd/user/gnome-remote-desktop.service
#      systemctl --user daemon-reload
#      systemctl --user enable --now gnome-remote-desktop
#    sonst läuft ewig die alte Version weiter.
#
#    Das VNC-Backend (Port 5900, Passwort via `grdctl vnc set-password`)
#    wird über das Overlay "grd-vnc" in overlays.nix einkompiliert —
#    nixpkgs baut GRD defaultmäßig nur mit RDP. Das Overlay patcht
#    libvncserver außerdem so, dass der Server Tight bevorzugt, sobald
#    der Client es anbietet (RFB wählt sonst das erste Encoding der
#    Client-Liste). dconf-Settings: modules/gnome
#    (org/gnome/desktop/remote-desktop/vnc).
{ lib, ... }:
{
  # Paket + Integration aktiv lassen (braucht auch der User-Daemon), aber:
  services.gnome.gnome-remote-desktop.enable = true;

  # System-Daemon ("Remote Login": RDP-Logins mit EIGENEN Headless-Sessions)
  # NICHT automatisch starten. Er belegt Port 3389 und fängt damit alle
  # RDP-Verbindungen ab, die zum USER-Daemon (Desktop Sharing, extend-Modus
  # aus modules/gnome) gehören — genau das passierte am 2026-11-24: Client
  # landete auf dem System-Daemon (Auth-Fehler "Could not find user in SAM
  # database", dessen Credentials via `sudo grdctl --system` gepflegt würden),
  # während der User-Daemon mit dem virtuellen Monitor kein einziges Paket
  # sah. Wer Remote Login doch will: wantedBy wieder auf graphical.target
  # setzen UND dem User-Daemon dann einen anderen RDP-Port gönnen.
  # TESTWEISE AKTIV (2026-11-24): Remote Login an, um den GDM-Dialog
  # "laufende Sitzung schließen?" gegen Sunshine abzuwägen. Der User-Daemon
  # (Desktop Sharing) ist per dconf aus, damit gibt es keinen Port-Konflikt.
  # Rückbau: wantedBy wieder auf lib.mkForce [ ] setzen.
  systemd.services."gnome-remote-desktop" = {
    wantedBy = lib.mkForce [ "graphical.target" ];
    restartIfChanged = false;
  };
}
