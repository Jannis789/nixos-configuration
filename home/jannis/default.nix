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
  # Hermes-API-Keys aus dem secrets-Flake-Input (siehe flake.nix).
  # Wird in modules/nixos/hermes-agent.nix ebenfalls importiert —
  # dort unter `services.hermes-agent.environment` (Upstream-Option,
  # die der NixOS-Aktivator in $HERMES_HOME/.env seedet; KEIN
  # `systemd.services.X.environment`, das waere die falsche Schicht).
  hermesApi = import (inputs.secrets + "/hermes-api.nix");
in
{
  home.username = userName;
  home.homeDirectory = "/home/${userName}";
  home.stateVersion = osConfig.system.homeStateVersion;

  # Hermes-API-Keys in die Desktop-Session exponieren, damit die
  # hermes-agent Electron-App (laeurt NICHT unter systemd, sondern
  # als User-Session-Prozess via gnome-session) dieselben Provider
  # sieht wie der NixOS-gateway.
  # Nutzt CUSTOM_*-Namen (keine nativen Plugin-Vars), damit
  # list_authenticated_providers() Section 1/2 nicht matched.
  # API_SERVER_KEY bleibt absichtlich draussen: das Token authentifiziert
  # nur den gateway auf 127.0.0.1:8642, nicht die Desktop-App.
  home.sessionVariables = {
    CUSTOM_ZAI_KEY       = hermesApi.ZAI_API_KEY;
    CUSTOM_OPENMODEL_KEY = hermesApi.OPENMODEL_API_KEY;
    NOUS_API_KEY         = hermesApi.NOUS_API_KEY;
  };

  imports = [
    ../../modules/home-manager/theme
    ../../modules/home-manager/gnome-extensions.nix
    ../../modules/home-manager/gnome-shell.nix
    ../../modules/home-manager/starship.nix
    ../../modules/home-manager/atuin.nix
    ../../modules/home-manager/vscode.nix
  ];

  programs = {
    home-manager.enable = true;
    bash = {
      enable = true;
      bashrcExtra = builtins.readFile homedir/.bashrc;
    };
  };

  home.file = {
    ".config" = {
      source = homedir/.config;
      recursive = true;
    };
    ".local" = {
      source = homedir/.local;
      recursive = true;
    };
    # ~/.hermes/config.yaml: BEWUSST NICHT hier hinterlegt. Ein
    # user-level Override der Embedded-Desktop-Runtime collidiert mit
    # dem NixOS-Modul services.hermes-agent.settings und hat in der
    # letzten Iteration zwei Regressionen erzeugt:
    #   1. dropdown verlor `zai`, weil `provider` in der YAML fehlte
    #      und Auto-Detect auf `nous` fiel.
    #   2. `default: vibethinker` ist KEIN Nous-Katalog-Eintrag ->
    #      404 auf inference-api.nousresearch.com/v1.
    # Wer Ollama-Local-Mode im Desktop will: erganzt per-model-Eintrag
    # in ~/.hermes/config.yaml (provider=openai,
    # base_url=http://localhost:11434/v1), oder im Settings-Dialog
    # des Desktop-Frontends.
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
