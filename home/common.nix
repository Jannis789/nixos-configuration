{
  config,
  lib,
  pkgs,
  inputs,
  osConfig,
  ...
}:  let
  userName = osConfig.system.userName;
  hermesApi = import (inputs.secrets + "/hermes-api.nix");
in
{
  home.username = userName;
  home.homeDirectory = "/home/${userName}";
  home.stateVersion = osConfig.system.homeStateVersion;

  home.sessionVariables = {
    CUSTOM_NOUS_KEY       = hermesApi.NOUS_API_KEY;
    CUSTOM_ZAI_KEY        = hermesApi.ZAI_API_KEY;
    CUSTOM_OPENMODEL_KEY  = hermesApi.OPENMODEL_API_KEY;
    CUSTOM_OPENROUTER_KEY = hermesApi.OPENROUTER_API_KEY;
    CUSTOM_CLOUDFLARE_KEY = hermesApi.CLOUDFLARE_API_KEY;
    CUSTOM_OPENCODE_KEY   = hermesApi.OPENCODE_API_KEY;
    NOUS_API_KEY          = hermesApi.NOUS_API_KEY;
  };

  imports = [
    ../modules/home-manager/theme
    ../modules/home-manager/gnome-extensions.nix
    ../modules/home-manager/gnome-shell.nix
    ../modules/home-manager/starship.nix
    ../modules/home-manager/atuin.nix
    ../modules/home-manager/vscode.nix
  ];

  programs = {
    home-manager.enable = true;
    bash = {
      enable = true;
      bashrcExtra = builtins.readFile ../homedir/${userName}/.bashrc;
    };
  };

  home.file = {
    ".config" = {
      source = ../homedir/${userName}/.config;
      recursive = true;
    };
    ".local" = {
      source = ../homedir/${userName}/.local;
      recursive = true;
    };
  };

  starship.profile = "default";
  atuin.profile = "default";
  vscode.profile = "default";

  gnome = {
    extensions = {
      install = [
        "user-themes"
        "color-picker"
        "blur-my-shell"
        "caffeine"
        "astra-monitor"
        "dash-to-dock"
        "tiling-shell"
      ];
      enable = [
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "color-picker@tuberry"
        "blur-my-shell@aunetx"
        "caffeine@patapon.info"
        "monitor@astraext.github.io"
        "dash-to-dock@micxgx.gmail.com"
        "tilingshell@ferrarodomenico.com"
      ];
    };

    shell = {
      favoriteApps = [
        "helium.desktop"
        "com.mitchellh.ghostty.desktop"
        "code.desktop"
        "org.gnome.Nautilus.desktop"
        "steam.desktop"
        "hermes-desktop.desktop"
      ];
    };

    dashToDock = {
      enable = true;
      position = "LEFT";
      extendHeight = true;
      fixed = true;
      shrink = true;
      straightCorner = true;
    };

    blurMyShell = {
      enable = true;
      overrideDashToDockBackground = false;
    };
  };

  home.packages = [
    inputs.nixvim.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  xdg.desktopEntries.hermes-desktop = {
    name = "Hermes Agent";
    genericName = "AI Assistant";
    comment = "Native Electron desktop shell for Hermes Agent";
    exec = "${pkgs.hermes-desktop}/bin/hermes-desktop %U";
    icon = "${pkgs.hermes-desktop}/share/hermes-desktop/dist/hermes.png";
    categories = [ "Utility" ];
    terminal = false;
    type = "Application";
  };
}
