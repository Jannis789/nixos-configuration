{ pkgs, ... }:

{
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-x86_64-v3;
  nix.settings.substituters = [
    "https://cache.nixos.org"
    "https://attic.xuyh0120.win/lantian"
  ];
  nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];

  theme.background = ../../etc/backgrounds/nixos-gradient.png;
  theme.gtk.name = "rewaita"; 
  theme.icons.name = "kora";
}
