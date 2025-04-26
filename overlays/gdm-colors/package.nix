{ config, pkgs, ... }:

{
  nixpkgs = {
    overlays = [
      (self: super: {
        gnome-shell = super.gnome-shell.overrideAttrs (old: {
          patches = (old.patches or []) ++ [
            (pkgs.substituteAll {
              src = ../../patches/gdm-colors.patch;
            })
          ];
        });
      })
    ];
  };
}