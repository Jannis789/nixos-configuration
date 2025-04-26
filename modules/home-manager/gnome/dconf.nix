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
        "floorp.desktop"
        "code.desktop"
        "org.gnome.Nautilus.desktop"
        "steam.desktop"
      ];
    };
  };
}