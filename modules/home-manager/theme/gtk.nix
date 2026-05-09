{ config, lib, pkgs, osConfig, ... }:

let
  r = osConfig.theme._resolved;
  isRewaita = osConfig.theme.gtk.name == "rewaita";
in
{
  config.gtk = lib.mkIf (osConfig.theme.gtk.name != "none") {
    enable = true;
    theme = {
      name = r.gtkThemeName;
      package = r.gtkThemePkg;
    };
    gtk4.theme = lib.mkIf (!isRewaita) {
      name = r.gtkThemeName;
      package = r.gtkThemePkg;
    };
  };
}
