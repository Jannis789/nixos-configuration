{
  config,
  lib,
  pkgs,
  inputs,
  hermesPkgs,
  ...
}:

let
  # ── Secrets ──────────────────────────────────────────────────────────────
  # Gleiche API-Keys wie auf NixOS, aus dem privaten secrets-Submodul.
  apiKeys = import (inputs.secrets + "/hermes-api.nix");

  # ── Custom Env-Var-Namen ─────────────────────────────────────────────────
  # Siehe modules/nixos/hermes-agent.nix für die Provider-Strategie.
  customKeys = {
    CUSTOM_ZAI_KEY       = apiKeys.ZAI_API_KEY;
    CUSTOM_OPENMODEL_KEY = apiKeys.OPENMODEL_API_KEY;
  };
  serverKey = { API_SERVER_KEY = apiKeys.API_SERVER_KEY; };
  nousKey   = { NOUS_API_KEY = apiKeys.NOUS_API_KEY; };

  # ── Provider-Konfiguration ───────────────────────────────────────────────
  myProviders = [
    {
      name = "ollama-local";
      base_url = "http://localhost:11434/v1";
      discover_models = false;
      models = [ "vibethinker" ];
    }
    {
      name = "zai-restricted";
      base_url = "https://api.z.ai/v1";
      key_env = "CUSTOM_ZAI_KEY";
      discover_models = false;
      models = [
        "glm-5.2" "glm-5.1" "glm-5v-turbo" "glm-4.5-flash"
      ];
    }
  ];

  openmodellProvider = {
    openmodell = {
      name = "openmodell";
      base_url = "https://api.openmodel.ai/v1";
      key_env = "CUSTOM_OPENMODEL_KEY";
      transport = "anthropic_messages";
      discover_models = false;
      models = [ "deepseek-v4-flash" ];
    };
  };

  modelRouting = {
    vibethinker = {
      provider = "openai";
      base_url = "http://localhost:11434/v1";
    };
    "glm-5.2" = {
      provider = "openai";
      base_url = "https://api.z.ai/v1";
      api_key_env = "CUSTOM_ZAI_KEY";
    };
    "glm-5.1" = {
      provider = "openai";
      base_url = "https://api.z.ai/v1";
      api_key_env = "CUSTOM_ZAI_KEY";
    };
    "glm-5v-turbo" = {
      provider = "openai";
      base_url = "https://api.z.ai/v1";
      api_key_env = "CUSTOM_ZAI_KEY";
    };
    "glm-4.5-flash" = {
      provider = "openai";
      base_url = "https://api.z.ai/v1";
      api_key_env = "CUSTOM_ZAI_KEY";
    };
    "openrouter/owl-alpha" = { provider = "nous"; };
    "deepseek/deepseek-v4-flash" = { provider = "nous"; };
    "qwen/qwen3.7-plus" = { provider = "nous"; };
    "minimax/minimax-m3" = { provider = "nous"; };
    "stepfun/step-3.7-flash:free" = { provider = "nous"; };
    "google/gemma-4-31b-it" = { provider = "nous"; };
    "tencent/hy3-preview" = { provider = "nous"; };
    "deepseek-v4-flash" = {
      provider = "anthropic";
      base_url = "https://api.openmodel.ai/v1";
      api_key_env = "CUSTOM_OPENMODEL_KEY";
    };
  };

  # ── Hermes config.yaml als Nix-Attrset → YAML ────────────────────────────
  yamlFormat = pkgs.formats.yaml { };

  hermesConfig = {
    model = {
      default = "deepseek/deepseek-v4-flash";
      provider = "auto";
      models = modelRouting;
    };
    custom_providers = myProviders;
    providers = openmodellProvider;
    model_catalog = {
      enabled = true;
      ttl_hours = 24;
      providers.nous.url = "https://raw.githubusercontent.com/Jannis789/nixos-configuration/master/model-catalog.json";
    };
    auxiliary = {
      vision            = { provider = "openai"; base_url = "https://api.z.ai/v1";             model = "glm-5v-turbo";          timeout = 120; };
      web_extract       = { provider = "openai"; base_url = "https://api.z.ai/v1";             model = "glm-5.2";               timeout = 360; };
      compression       = { provider = "openai"; base_url = "https://api.z.ai/v1";             model = "glm-4.5-flash";         timeout = 120; };
      skills_hub        = { provider = "openai"; base_url = "https://api.z.ai/v1";             model = "glm-4.5-flash";         timeout = 30;  };
      approval          = { provider = "openai"; base_url = "https://api.z.ai/v1";             model = "glm-5.2";               timeout = 30;  };
      mcp               = { provider = "openai"; base_url = "https://api.z.ai/v1";             model = "glm-4.5-flash";         timeout = 30;  };
      title_generation  = { provider = "nous";                                                model = "google/gemma-4-31b-it"; timeout = 30;  };
      triage_specifier  = { provider = "openai"; base_url = "https://api.z.ai/v1";             model = "glm-5.1";               timeout = 120; };
      kanban_decomposer = { provider = "openai"; base_url = "https://api.z.ai/v1";             model = "glm-5.1";               timeout = 180; };
      curator           = { provider = "openai"; base_url = "https://api.z.ai/v1";             model = "glm-4.5-flash";         timeout = 600; };
      profile_describer = { provider = "openai"; base_url = "https://api.z.ai/v1";             model = "glm-4.5-flash";         timeout = 60;  };
    };
    compression = {
      enabled = true;
      threshold = 0.50;
      target_ratio = 0.20;
    };
  };

  hermesConfigYAML = yamlFormat.generate "config.yaml" hermesConfig;
in
{
  home.username = "jrustige";
  home.homeDirectory = "/Users/jrustige";
  home.stateVersion = "25.05";

  # ── Session-Variablen für API-Keys ──────────────────────────────────────
  # Gleiche CUSTOM_*-Namen wie auf NixOS, damit built-in Provider-Checks
  # Section 1/2 nicht matchen.
  home.sessionVariables = nousKey // customKeys // serverKey;

  # ── Hermes config.yaml ──────────────────────────────────────────────────
  # Überschreibt die manuell installierte Config. Nach Deinstallation
  # der manuellen Hermes-Version via `hermes uninstall` bleibt die Config
  # erhalten.
  home.file.".hermes/config.yaml".source = hermesConfigYAML;

  # ── Packages ─────────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    # Nixvim aus dem separaten Flake
    inputs.nixvim.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Nützliche CLI-Tools
    btop
    fastfetch
    git
    wget
    starship
    atuin
    zoxide
    nixfmt
    openssh
    unzip
    tree
    fzf
    sqlite
    python3
    nodejs
    ripgrep
    fd
  ];

  # ── Programme ────────────────────────────────────────────────────────────
  programs = {
    home-manager.enable = true;

    bash = {
      enable = true;
      bashrcExtra = ''
        # macOS PATH-Anpassung
        export PATH="/opt/homebrew/bin:$PATH"
        export PATH="$HOME/.local/bin:$PATH"
      '';
    };

    starship.enable = true;
    atuin.enable = true;
  };

  # ── Desktop-Eintrag für Hermes Desktop ──────────────────────────────────
  # Wird auf Darwin nicht unterstützt (xdg.desktopEntries ist Linux-only).
  # Stattdessen: macOS-Nutzer starten hermes-desktop manuell oder via
  # home-manager's `home.activation` oder LaunchAgent. Für später.
  #
  # xdg.desktopEntries.hermes-desktop = {
  #   name = "Hermes Agent";
  #   genericName = "AI Assistant";
  #   comment = "Native Electron desktop shell for Hermes Agent";
  #   exec = "${hermesPkgs.desktop}/bin/hermes-desktop %U";
  #   icon = "${hermesPkgs.desktop}/share/hermes-desktop/dist/hermes.png";
  #   categories = [ "Utility" ];
  #   terminal = false;
  #   type = "Application";
  # };
}
