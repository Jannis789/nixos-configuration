{
  config,
  lib,
  pkgs,
  inputs,
  osConfig,
  ...
}:

let
  userName = osConfig.system.userName;
in
{
  home.username = userName;
  home.homeDirectory = "/home/${userName}";
  home.stateVersion = osConfig.system.homeStateVersion;

  imports = [
    ../modules/home-manager/theme
    ../modules/home-manager/gnome-extensions.nix
    ../modules/home-manager/gnome-shell.nix
    ../modules/home-manager/starship.nix
    ../modules/home-manager/atuin.nix
    ../modules/home-manager/vscode.nix
    ../modules/home-manager/zen-browser.nix
    inputs.zen-browser.homeModules.beta
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

  zen-browser = {
    profile = "default";
    theme = "Mocha";
    accent = "Lavender";
  };

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
        "zen-beta.desktop"
        "com.mitchellh.ghostty.desktop"
        "code.desktop"
        "org.gnome.Nautilus.desktop"
        "steam.desktop"
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
}
