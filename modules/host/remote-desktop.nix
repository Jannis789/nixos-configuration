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
{ ... }:
{
  services.gnome.gnome-remote-desktop.enable = true;
  systemd.services."gnome-remote-desktop" = {
    wantedBy = [ "graphical.target" ];
    restartIfChanged = false;
  };
}
