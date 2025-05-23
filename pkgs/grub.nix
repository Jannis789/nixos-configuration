{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    theme = inputs.nixos-grub-themes.packages.${pkgs.system}.hyperfluent;
    devices = [ "nodev" ];
    gfxmodeEfi = "2560x1440";
  };
}
