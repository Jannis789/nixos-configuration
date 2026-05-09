{ config, lib, osConfig, ... }:

let
  themeCfg = osConfig.theme;
  r = themeCfg._resolved;
  isRewaita = themeCfg.gtk.name == "rewaita";

  userThemeSettings = {
    "org/gnome/shell/extensions/user-theme" = {
      name = if isRewaita then "rewaita" else r.gtkThemeName;
    };
  };

  backgroundSettings = lib.optionalAttrs (themeCfg.background != null) {
    "org/gnome/desktop/background" = {
      picture-uri = "file://${toString themeCfg.background}";
      picture-uri-dark = "file://${toString themeCfg.background}";
    };
  };
in
{
  config.dconf.settings = lib.mkMerge [
    {
      "org/gnome/desktop/interface" = {
        color-scheme = themeCfg.colorScheme;
      };
      "org/gnome/desktop/input-sources/sources" = {
        sources = "[('xkb', 'de'), ('xkb', 'us')]";
      };
    }
    userThemeSettings
    backgroundSettings
  ];
}
