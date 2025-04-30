{ config, pkgs, ... }:

{
  programs.gamemode.enable = true;
  environment.systemPackages = with pkgs; [
    protonplus
    steam
    lutris
    mangohud
    protonup
    heroic
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "amdgpu" ];

  environment.sessionVariables = rec {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/$USER/.steam/root/compatibilitytools.d";
  };
}
