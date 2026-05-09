{ config, lib, ... }:

let
  cfg = config.gnome;
in
{
  options.gnome = {
    shell = {
      favoriteApps = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
      inputSources = lib.mkOption {
        type = lib.types.str;
        default = "[('xkb', 'de'), ('xkb', 'us')]";
      };
    };

    dashToDock = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      position = lib.mkOption {
        type = lib.types.enum [
          "LEFT"
          "RIGHT"
          "BOTTOM"
          "TOP"
        ];
        default = "LEFT";
      };
      extendHeight = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      fixed = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      shrink = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      straightCorner = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };

    blurMyShell = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      overrideDashToDockBackground = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  };

  config.dconf.settings = lib.mkMerge [
    {
      "org/gnome/shell" = {
        favorite-apps = cfg.shell.favoriteApps;
      };
    }
    (lib.mkIf cfg.dashToDock.enable {
      "org/gnome/shell/extensions/dash-to-dock" = {
        dock-position = cfg.dashToDock.position;
        apply-custom-theme = false;
        extend-height = cfg.dashToDock.extendHeight;
        custom-theme-shrink = cfg.dashToDock.shrink;
        force-straight-corner = cfg.dashToDock.straightCorner;
        dock-fixed = cfg.dashToDock.fixed;
      };
    })
    (lib.mkIf cfg.blurMyShell.enable {
      "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
        override-background = cfg.blurMyShell.overrideDashToDockBackground;
      };
    })
  ];
}
