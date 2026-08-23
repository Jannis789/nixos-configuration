{ config, lib, pkgs, ... }:
{
  # GNOME Dash/Dock: Pinned Apps + Dash-to-Dock + Blur
  # (aus rewrite/09_gnome_dconf.md + alter Config)
  dconf.settings = {
    # Pinned Apps (favorite-apps)
    "org/gnome/shell" = {
      favorite-apps = [
        "helium.desktop"
        "com.mitchellh.ghostty.desktop"
        "code-insiders.desktop"
        "org.gnome.Nautilus.desktop"
        "steam.desktop"
      ];
    };

    # Dash to Dock: links, volle Höhe, fest
    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-position = "LEFT";
      extend-height = true;
      dock-fixed = true;
      custom-theme-shrink = true;
      force-straight-corner = true;
      apply-custom-theme = false;
    };

    # Blur My Shell: Dock-Hintergrund nicht überschreiben
    "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
      override-background = false;
    };
  };


}
