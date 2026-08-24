{
  config,
  lib,
  pkgs,
  ...
}:
{
  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "helium.desktop"
        "com.mitchellh.ghostty.desktop"
        "code-insiders.desktop"
        "org.gnome.Nautilus.desktop"
        "steam.desktop"
      ];
    };

    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-position = "LEFT";
      extend-height = true;
      dock-fixed = true;
      custom-theme-shrink = true;
      force-straight-corner = true;
      apply-custom-theme = false;
    };

    "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
      override-background = false;
    };
  };
}
