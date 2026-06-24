# modules/nixos/hermes-agent.nix
#
# Hermes-Agent NixOS Service.
#
# Provider-Strategie (hybrid):
#   ollama, zai, openmodel: custom_providers (discover_models: false) →
#     Picker zeigt exakt die gelisteten Modelle.
#   nous: native plugin + model_catalog Override →
#     Built-in nous zeigt NUR die Modelle aus model-catalog.json.
#     Keine endpoint-Deduplication in Section 4, weil wir keinen
#     custom_provider für nous definieren.
#
# API-Keys:
#   NOUS_API_KEY       — nativer nous-Plugin (built-in, model_catalog
#                        restricted).
#   CUSTOM_ZAI_KEY     — openai-compat routing zu api.z.ai.
#   CUSTOM_OPENMODEL_KEY — anthropic-compat routing zu api.openmodel.ai.
#   KEIN ZAI_API_KEY / OPENMODEL_API_KEY / OPENAI_API_KEY —
#     damit Section 1/2 keine built-in zai/openai Einträge zeigt.
{ config, lib, pkgs, inputs, ... }:

let
  # `inputs.secrets` ist ein `git+file:`-Flake-Input auf das private
  # secrets-Submodul (siehe flake.nix).
  apiKeys = import (inputs.secrets + "/hermes-api.nix");

  # ── Custom Env-Var-Namen (für custom_providers) ───────────────────────
  # Werden statt der nativen Plugin-Vars ins Environment gelegt, damit
  # Section 1/2 keine Credentials für zai/openai sieht.
  customKeys = {
    CUSTOM_ZAI_KEY      = apiKeys.ZAI_API_KEY;
    CUSTOM_OPENMODEL_KEY = apiKeys.OPENMODEL_API_KEY;
  };

  # API_SERVER_KEY bleibt nativ (kein built-in Provider-Check dafuer).
  serverKey = { API_SERVER_KEY = apiKeys.API_SERVER_KEY; };

  # NOUS_API_KEY wird natv gesetzt — built-in nous + model_catalog
  # Override ersetzen den custom_provider für nous.
  nousKey = { NOUS_API_KEY = apiKeys.NOUS_API_KEY; };

  # ── custom_providers (Section 4 im Picker) — NUR für openai-compat ───
  # nous fehlt bewusst: das läuft über built-in + model_catalog.
  myProviders = [
    {
      name = "ollama-local";
      base_url = "http://localhost:11434/v1";
      discover_models = false;
      models = [ "vibethinker" ];
    }
    {
      name = "zai-restricted";
      base_url = "https://api.z.ai/api/paas/v4";
      key_env = "CUSTOM_ZAI_KEY";
      discover_models = false;
      models = [
        "glm-5.2"
        "glm-5.1"
        "glm-5v-turbo"
        "glm-4.5-flash"
      ];
    }
  ];

  # ── providers (Section 3 im Picker) — openmodell ─────────────────────
  # resolve_user_provider() liest key_env und transport korrekt.
  # Braucht transport = "anthropic_messages" weil openmodel.ai nur
  # Anthropic Messages spricht, kein OpenAI chat/completions.
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

  # ── model.models (Routing-Tabelle) ────────────────────────────────────
  # Flat: model-Name → Routing. Openai-compat für custom_providers,
  # natives Plugin für nous.
  modelRouting = {
    # ollama (openai-compat)
    vibethinker = {
      provider = "openai";
      base_url = "http://localhost:11434/v1";
    };

    # z.ai (openai-compat — /api/paas/v4, NICHT /v1)
    "glm-5.2" = {
      provider = "openai";
      base_url = "https://api.z.ai/api/paas/v4";
      api_key_env = "CUSTOM_ZAI_KEY";
    };
    "glm-5.1" = {
      provider = "openai";
      base_url = "https://api.z.ai/api/paas/v4";
      api_key_env = "CUSTOM_ZAI_KEY";
    };
    "glm-5v-turbo" = {
      provider = "openai";
      base_url = "https://api.z.ai/api/paas/v4";
      api_key_env = "CUSTOM_ZAI_KEY";
    };
    "glm-4.5-flash" = {
      provider = "openai";
      base_url = "https://api.z.ai/api/paas/v4";
      api_key_env = "CUSTOM_ZAI_KEY";
    };

    # Nous (natives Plugin — model_catalog restricted)
    "openrouter/owl-alpha" = { provider = "nous"; };
    "deepseek/deepseek-v4-flash" = { provider = "nous"; };
    "qwen/qwen3.7-plus" = { provider = "nous"; };
    "minimax/minimax-m3" = { provider = "nous"; };
    "stepfun/step-3.7-flash:free" = { provider = "nous"; };
    "google/gemma-4-31b-it" = { provider = "nous"; };
    "tencent/hy3-preview" = { provider = "nous"; };

    # openmodel.ai (anthropic-compat — /v1/messages, nicht /v1/chat/completions)
    "deepseek-v4-flash" = {
      provider = "anthropic";
      base_url = "https://api.openmodel.ai/v1";
      api_key_env = "CUSTOM_OPENMODEL_KEY";
    };
  };

in
{
  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    extraDependencyGroups = [ "anthropic" ];

    settings = {
      # ── Modell ────────────────────────────────────────────────────────
      model = {
        default = "deepseek/deepseek-v4-flash";
        provider = "auto";
        models = modelRouting;
      };

      # ── Custom Provider (ollama, zai) — openai-compat ─────────────────
      custom_providers = myProviders;

      # ── User Provider (openmodell) — anthropic-messages compat ───────
      providers = openmodellProvider;

      # ── model_catalog — nous-Restriktion ──────────────────────────────
      # Nur der `nous`-Provider bekommt ein eigenes Catalog-JSON mit den
      # gewünschten Modellen. openrouter bleibt beim Standard.
      model_catalog = {
        enabled = true;
        ttl_hours = 24;
        providers.nous.url = "https://raw.githubusercontent.com/Jannis789/nixos-configuration/master/model-catalog.json";
      };

      # ── Auxiliary Tasks ───────────────────────────────────────────────
      # zai-Modelle: openai-compat (custom_providers Key)
      # nous-Modelle: native plugin
      auxiliary = {
        vision             = { provider = "openai"; base_url = "https://api.z.ai/api/paas/v4";             model = "glm-5v-turbo";          timeout = 120; };
        web_extract        = { provider = "openai"; base_url = "https://api.z.ai/api/paas/v4";             model = "glm-5.2";               timeout = 360; };
        compression        = { provider = "openai"; base_url = "https://api.z.ai/api/paas/v4";             model = "glm-4.5-flash";         timeout = 120; };
        skills_hub         = { provider = "openai"; base_url = "https://api.z.ai/api/paas/v4";             model = "glm-4.5-flash";         timeout = 30;  };
        approval           = { provider = "openai"; base_url = "https://api.z.ai/api/paas/v4";             model = "glm-5.2";               timeout = 30;  };
        mcp                = { provider = "openai"; base_url = "https://api.z.ai/api/paas/v4";             model = "glm-4.5-flash";         timeout = 30;  };
        title_generation   = { provider = "nous";                                                model = "google/gemma-4-31b-it"; timeout = 30;  };
        triage_specifier   = { provider = "openai"; base_url = "https://api.z.ai/api/paas/v4";             model = "glm-5.1";               timeout = 120; };
        kanban_decomposer  = { provider = "openai"; base_url = "https://api.z.ai/api/paas/v4";             model = "glm-5.1";               timeout = 180; };
        curator            = { provider = "openai"; base_url = "https://api.z.ai/api/paas/v4";             model = "glm-4.5-flash";         timeout = 600; };
        profile_describer  = { provider = "openai"; base_url = "https://api.z.ai/api/paas/v4";             model = "glm-4.5-flash";         timeout = 60;  };
      };

      # ── Compression defaults ──────────────────────────────────────────
      compression = {
        enabled = true;
        threshold = 0.50;
        target_ratio = 0.20;
      };
    };
  };

  # API-Keys: NOUS_API_KEY nativ (built-in nous), CUSTOM_* für
  # custom_providers (zai, openmodel). Kein ZAI_API_KEY / OPENMODEL_API_KEY
  # / OPENAI_API_KEY — damit built-in Provider-Checks nicht matchen.
  services.hermes-agent.environment = nousKey // customKeys // serverKey;
}
