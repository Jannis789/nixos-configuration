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
  # Hermes-API-Keys aus dem secrets-Flake-Input (`path:`-URL, kein
  # Git-Tracker involviert — siehe flake.nix fuer die Begruendung).
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
  # hermes-desktop Electron-App (laeuft NICHT unter systemd, sondern
  # als User-Session-Prozess via gnome-session) dieselben Provider
  # sieht wie der NixOS-gateway.
  # API_SERVER_KEY bleibt absichtlich draussen: das Token authentifiziert
  # nur den gateway auf 127.0.0.1:8642, nicht die Desktop-App.
  home.sessionVariables = {
    ZAI_API_KEY       = hermesApi.ZAI_API_KEY;
    NOUS_API_KEY      = hermesApi.NOUS_API_KEY;
    OPENAI_API_KEY    = hermesApi.OPENAI_API_KEY;
    OPENMODEL_API_KEY = hermesApi.OPENMODEL_API_KEY;
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
  #
  # Routing: hermes-desktop spawnt beim Start sein eigenes Embedded-
  # hermes-agent (Python-Runtime aus dem backing Flake). Modell/Provider
  # kommt vollstandig aus dem NixOS-Modul services.hermes-agent.settings —
  # siehe modules/nixos/hermes-agent.nix (deepseek-v4-flash,
  # provider=auto). FRUHERE VERSUCHE, dies via HERMES_DESKTOP_REMOTE_URL
  # oder per home-manager-write in ~/.hermes/config.yaml zu losen, haben
  # zwei Regressionen erzeugt: (1) dropdown verlor zai, (2) default wurde
  # auf `vibethinker` umgebogen -> 404 auf inference-api.nousresearch.com.
  # Daher jetzt konsequent nur das NixOS-Modul als Single-Source-of-Truth.
  # Der NixOS-gateway-Service (hermes-agent.service) bleibt auf
  # 127.0.0.1:8642 hochverfuegbar (API_SERVER_KEY via
  # services.hermes-agent.environment in modules/nixos/hermes-agent.nix)
  # fuer CLI-Use, WebHooks und spatere Remote-Desktop-Routen.
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
