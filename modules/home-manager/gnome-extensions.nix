{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.gnome;
in
{
  options.gnome = {
    disableUserExtensions = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    extensions = {
      install = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
      enable = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
    };
  };

  config = {
    home.packages = map (ext: pkgs.gnomeExtensions.${ext}) cfg.extensions.install;

    dconf.settings = {
      "org/gnome/shell" = {
        disable-user-extensions = cfg.disableUserExtensions;
        enabled-extensions = cfg.extensions.enable;
      };
    };
  };
}
