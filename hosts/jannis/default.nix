{ config, lib, pkgs, ... }:

{
  networking.hostName = "jannis";
  programs.nix-ld.enable = true;

  imports = [
    ../../modules/nixos/hermes-agent.nix
  ];

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
