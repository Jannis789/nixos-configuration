{ config, pkgs, ... }:

{
  systemd.services.gnome-remote-desktop = {
    wantedBy = [ "graphical.target" ];
  };
  systemd.sleep.extraConfig = ''
  AllowSuspend=no
  AllowHibernation=no
  AllowHybridSleep=no
  AllowSuspendThenHibernate=no
  '';

  environment.systemPackages = with pkgs; [
        gnome-session
        gnome-remote-desktop
  ];

  networking.firewall.allowedTCPPorts = [ 3390 ];
  services.gnome.gnome-remote-desktop.enable = true;

}