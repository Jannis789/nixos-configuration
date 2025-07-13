# overlays/extra-pkgs.nix
self: super: {
  andromeda-gtk-theme = super.callPackage ./andromeda-gtk-theme/package.nix {  };
}