{ pkgs, ... }:

{
  nixpkgs.overlays = [
    (self: super: {
      gnome-shell = super.gnome-shell.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          (self.replaceVars ../../etc/patches/gdm-colors.patch { })
        ];
      });
    })
  ];
}
