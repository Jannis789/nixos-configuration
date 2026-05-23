{
  config,
  lib,
  pkgs,
  ...
}:

{
  networking.hostName = "jannis";
  programs.nix-ld.enable = true;

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    settings.model = "zai/glm-5.1";
    environmentFiles = [ ./../../secrets/hermes-env ];
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      mesa
      vulkan-loader
      vulkan-tools
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      mesa
      vulkan-loader
    ];
  };
}
