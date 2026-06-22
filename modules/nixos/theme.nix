{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theme;

  capitalize =
    s:
    let
      len = builtins.stringLength s;
    in
    if len == 0 then
      ""
    else
      let
        first = lib.toUpper (builtins.substring 0 1 s);
        rest = builtins.substring 1 (len - 1) s;
      in
      first + rest;

  gtkRegistry = {
    catppuccin =
      name: pkg:
      if cfg.catppuccin.enable then
        {
          inherit name pkg;
        }
      else
        {
          name = "Adwaita";
          pkg = pkgs.gnome-themes-extra;
        };
    adwaita = {
      name = "Adwaita";
      pkg = pkgs.gnome-themes-extra;
    };
    none = {
      name = "";
      pkg = null;
    };
  };

  iconRegistry = {
    papirus = {
      name = "Papirus-Dark";
      pkg = pkgs.papirus-icon-theme;
    };
    kora = {
      name = "kora";
      pkg = pkgs.kora-icon-theme;
    };
    adwaita = {
      name = "Adwaita";
      pkg = null;
    };
    none = {
      name = "";
      pkg = null;
    };
  };

  cursorRegistry = {
    adwaita = {
      name = "Adwaita";
      pkg = null;
    };
    none = {
      name = "";
      pkg = null;
    };
  };

  resolvedGtk = gtkRegistry.${cfg.gtk.name} or gtkRegistry.none;
  resolvedIcon = iconRegistry.${cfg.icons.name} or iconRegistry.none;
  resolvedCursor = cursorRegistry.${cfg.cursor.name} or cursorRegistry.none;
in
{
  options.theme = {
    colorScheme = lib.mkOption {
      type = lib.types.enum [
        "prefer-dark"
        "prefer-light"
      ];
      default = "prefer-dark";
    };

    background = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };

    catppuccin = {
      enable = lib.mkEnableOption "Catppuccin GTK theme" // {
        default = true;
      };
      flavor = lib.mkOption {
        type = lib.types.enum [
          "mocha"
          "macchiato"
          "frappe"
          "latte"
        ];
        default = "mocha";
      };
      accent = lib.mkOption {
        type = lib.types.enum [
          "blue"
          "flamingo"
          "green"
          "grey"
          "lavender"
          "maroon"
          "mauve"
          "peach"
          "pink"
          "red"
          "rosewater"
          "sapphire"
          "sky"
          "teal"
          "yellow"
        ];
        default = "lavender";
      };
      shade = lib.mkOption {
        type = lib.types.enum [
          "dark"
          "light"
        ];
        default = "dark";
      };
      size = lib.mkOption {
        type = lib.types.enum [
          "standard"
          "compact"
        ];
        default = "standard";
      };
      tweaks = lib.mkOption {
        type = lib.types.listOf (
          lib.types.enum [
            "frappe"
            "macchiato"
            "black"
            "blackness"
            "float"
            "macos"
          ]
        );
        default = [
          "macos"
        ];
      };
    };

    gtk = {
      name = lib.mkOption {
        type = lib.types.enum [
          "catppuccin"
          "graphite"
          "orchis"
          "juno"
          "rewaita"
          "adwaita"
          "none"
        ];
        default = "catppuccin";
      };
    };

    icons = {
      name = lib.mkOption {
        type = lib.types.enum [
          "papirus"
          "kora"
          "adwaita"
          "none"
        ];
        default = "adwaita";
      };
    };

    cursor = {
      name = lib.mkOption {
        type = lib.types.enum [
          "adwaita"
          "none"
        ];
        default = "adwaita";
      };
    };

    terminal = {
      font = lib.mkOption {
        type = lib.types.str;
        default = "FiraCode Nerd Font Medium 12";
      };
      theme = lib.mkOption {
        type = lib.types.str;
        default = "Dracula";
      };
    };

    vscode = {
      colorTheme = lib.mkOption {
        type = lib.types.str;
        default = "Catppuccin Mocha";
      };
    };

    _resolved = {
      gtkThemeName = lib.mkOption {
        type = lib.types.str;
        internal = true;
      };
      gtkThemePkg = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        internal = true;
      };
      iconName = lib.mkOption {
        type = lib.types.str;
        internal = true;
      };
      iconPkg = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        internal = true;
      };
      cursorName = lib.mkOption {
        type = lib.types.str;
        internal = true;
      };
    };
  };

  config = {
    theme._resolved = {
      gtkThemeName =
        if cfg.gtk.name == "catppuccin" && cfg.catppuccin.enable then
          "Catppuccin-GTK-Theme-${capitalize cfg.catppuccin.accent}-${capitalize cfg.catppuccin.shade}"
        else if cfg.gtk.name == "graphite" then
          "Graphite-Dark"
        else if cfg.gtk.name == "orchis" then
          "Orchis-Dark"
        else if cfg.gtk.name == "juno" then
          "Juno"
        else if cfg.gtk.name == "rewaita" then
          "Adwaita"
        else if cfg.gtk.name == "adwaita" then
          "Adwaita"
        else
          "";
      gtkThemePkg =
        if cfg.gtk.name == "catppuccin" && cfg.catppuccin.enable then
          pkgs.catppuccin-gtk
        else if cfg.gtk.name == "graphite" then
          pkgs.graphite-gtk-theme
        else if cfg.gtk.name == "orchis" then
          pkgs.orchis-theme
        else if cfg.gtk.name == "juno" then
          pkgs.juno-theme
        else if cfg.gtk.name == "rewaita" then
          null
        else if cfg.gtk.name == "adwaita" then
          pkgs.gnome-themes-extra
        else
          null;
      iconName = resolvedIcon.name;
      iconPkg = resolvedIcon.pkg;
      cursorName = resolvedCursor.name;
    };

    nixpkgs.overlays = lib.mkIf cfg.catppuccin.enable [
      (final: prev: {
        catppuccin-gtk = prev.callPackage ../../etc/custom_pkgs/catppuccin-gtk.nix {
          accent = [ cfg.catppuccin.accent ];
          shade = cfg.catppuccin.shade;
          size = cfg.catppuccin.size;
          tweaks = cfg.catppuccin.tweaks;
        };
      })
    ];
  };
}
