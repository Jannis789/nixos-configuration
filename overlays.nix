final: prev:

{
  hatter-icon-theme = prev.callPackage ./etc/custom_pkgs/hatter-icon-theme.nix { };
  rewaita-custom = prev.callPackage ./etc/custom_pkgs/rewaita-custom.nix { };
  midori-desktop = prev.callPackage ./etc/custom_pkgs/midori-desktop.nix { };
  helium = prev.callPackage ./etc/custom_pkgs/helium.nix { };
}
