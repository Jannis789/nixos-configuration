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

  # Hermes-Desktop User-Level XDG-Integration: das Upstream-Paket aus
  # inputs.hermes-agent.packages.<system>.desktop liefert kein .desktop-File
  # und keinen Icon-Theme-Treffer. Wir packen es hier NICHT in einen runCommand-
  # Wrap, sondern legen nur einen User-Level .desktop-Eintrag in
  # ~/.local/share/applications/ an und nutzen das Upstream-Icon direkt.
  # Damit ist die Aenderung vollstaendig zrueckrollbar und greift nicht in
  # die Upstream-Derivation ein.
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
