{ config, pkgs , ... }:

{  
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
    };
    "org/gnome/shell" = {

      favorite-apps = [
        "org.gnome.Console.desktop"
        "librewolf.desktop"
        "code.desktop"
        "org.gnome.Nautilus.desktop"
        "steam.desktop"
      ];
    };

    "org/gnome/desktop/background" = {
      color-shading-type = "solid";
      picture-uri-dark = "file://" +  ../../../img/nix-wallpaper-catppuccin-macchiato.png;
    };
  };
}