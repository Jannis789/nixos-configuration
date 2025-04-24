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

    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };

    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };

  };

  home.sessionVariables.GTK_THEME = "Catppuccin-Dark";
}