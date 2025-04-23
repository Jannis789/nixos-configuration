{ config, pkgs, ... }:

{
  gtk = {
    enable = true;

    theme = {
      name = "Catppuccin-Dark";
      package = pkgs.catppuccin-gtk-theme;
    };
  };

  home.sessionVariables.GTK_THEME = "Catppuccin-Dark";
}