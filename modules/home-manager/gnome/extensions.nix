{ config, pkgs, ... }:

{
  dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false;

      enabled-extensions = [
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "color-picker@tuberry"
        "blur-my-shell@aunetx"
        "caffeine@patapon.info"
        "monitor@astraext.github.io"
        "dash-to-dock@micxgx.gmail.com"
      ];
    };

    "org/gnome/shell/extensions/user-theme" = {
      name = "Catppuccin-GTK-Dark";
    };

    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-position = "LEFT";
      apply-custom-theme = true;
      extend-height = true;
      custom-theme-shrink = true;
      force-straight-corner = true;
      dock-fixed = true;
    };

    "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
      pipeline = "pipeline_default";
    };
  };

  home.packages = with pkgs.gnomeExtensions; [
    user-themes
    color-picker
    blur-my-shell
    caffeine
    astra-monitor
    dash-to-dock
  ];
}
