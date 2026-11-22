{ ... }:
{
  imports = [
    ./dock.nix
    ./extensions.nix
  ];

  dconf.settings."org/gnome/settings-daemon/plugins/power" = {
    sleep-inactive-ac-type = "nothing";
    sleep-inactive-battery-type = "nothing";
  };

  # VNC-Freigabe über gnome-remote-desktop. Das VNC-Backend wird erst durch
  # das Overlay "grd-vnc" (overlays.nix) in den Daemon einkompiliert —
  # nixpkgs baut GRD defaultmäßig nur mit RDP.
  #
  # Das VNC-Passwort liegt im GNOME-Keyring und ist nicht declarativ
  # setzbar; einmalig in der grafischen Session ausführen:
  #   grdctl vnc set-password '...'
  dconf.settings."org/gnome/desktop/remote-desktop/vnc" = {
    enable = true;
    view-only = false; # Maus/Tastatur-Eingaben erlauben
    auth-method = "password"; # Passwort-Auth statt Freigabe-Dialog am Host
  };
}
