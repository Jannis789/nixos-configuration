# overlays/overlays.nix
self: super: {
  catppuccin-gtk-theme = super.callPackage pkgs/catppuccin-gtk-theme/package.nix { };
}