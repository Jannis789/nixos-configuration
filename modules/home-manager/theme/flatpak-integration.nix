{ config, lib, pkgs, osConfig, ... }:

let
  r = osConfig.theme._resolved;
  isRewaita = osConfig.theme.gtk.name == "rewaita";

  gtkThemeFiles =
    if isRewaita then { }
    else lib.optionalAttrs (r.gtkThemePkg != null && r.gtkThemeName != "") {
      ".local/share/themes/${r.gtkThemeName}".source = "${r.gtkThemePkg}/share/themes/${r.gtkThemeName}";
    };

  iconThemeFiles = lib.optionalAttrs (r.iconPkg != null && r.iconName != "") {
    ".local/share/icons/${r.iconName}".source = "${r.iconPkg}/share/icons/${r.iconName}";
  };
in
{
  config.home.file = lib.mkMerge [
    gtkThemeFiles
    iconThemeFiles
  ];
}
