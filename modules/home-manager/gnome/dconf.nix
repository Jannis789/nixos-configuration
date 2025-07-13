{ config, pkgs, ... }:

{
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
    };
    "org/gnome/shell" = {

      favorite-apps = [
        "com.raggesilver.BlackBox.desktop"
        "librewolf.desktop"
        "code.desktop"
        "org.gnome.Nautilus.desktop"
        "steam.desktop"
      ];
    };

    "org/gnome/desktop/background" = {
      color-shading-type = "solid";
      picture-uri-dark = "file://" + ../../../img/nix-wallpaper-catppuccin-macchiato.png;
    };

    "org/gnome/Console" = {
      use-system-font = false;
      custom-font = "FiraCode Nerd Font Mono 12";
    };

    "com/raggesilver/BlackBox" = {
      font = "FiraCode Nerd Font Medium 12";
    };

    "com/raggesilver/BlackBox" = {
      "theme-dark" = "Catppuccin Mocha";
    };
    
    "org/gnome/desktop/remote-desktop/rdp" = {
      enable = true;
      view-only = false;
    };
  };
}
