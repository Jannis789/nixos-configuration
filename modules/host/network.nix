{ ... }:
{
  networking.networkmanager.enable = true;

  networking.interfaces.enp6s0.wakeOnLan.enable = true; # Magic-Packet only

  networking.firewall.allowedTCPPorts = [
    22
    3389
    443
    5900 # VNC (gnome-remote-desktop mit VNC-Backend, Overlay "grd-vnc")
  ];

  services.tailscale.enable = true;
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
}
