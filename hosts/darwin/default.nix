{ config, pkgs, hermesPkgs, ... }:

{
  networking.hostName = "darwin";

  environment.systemPackages = with pkgs; [
    (hermesPkgs.default.override { extraDependencyGroups = [ "anthropic" ]; })
    hermesPkgs.desktop
  ];

  system.primaryUser = config.system.userName;
  system.defaults = {
    dock.autohide = true;
    finder.ShowPathbar = true;
    finder.ShowStatusBar = true;
  };

  time.timeZone = "Europe/Berlin";

  services.openssh = {
    enable = true;
    extraConfig = ''
      PermitRootLogin no
      PasswordAuthentication no
    '';
  };
}
