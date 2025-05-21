# modules/home-manager/gnome/gtk.nix

{ config, pkgs, ... }:

{
  gtk = {
    enable = true;

    theme = {
      name = "Catppuccin-Dark";
      package = pkgs.catppuccin-gtk-theme;
    };

    iconTheme = {
      name = "Colloid";
      package = pkgs.colloid-icon-theme;
    };

    cursorTheme = {
      name = "graphite-dark";
      package = pkgs.graphite-cursors;
    };
  };

  home.sessionVariables.GTK_THEME = "Catppuccin-Dark";
}
