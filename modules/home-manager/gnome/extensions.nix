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
      ];
    };

    "org/gnome/shell/extensions/user-theme" = {
      name = "Catppuccin-Dark";
    };


  };
  # /org/gnome/shell/extensions/user-theme/
  home.packages = with pkgs.gnomeExtensions; [
    user-themes
    color-picker
    blur-my-shell
    caffeine
    astra-monitor
  ];
}
