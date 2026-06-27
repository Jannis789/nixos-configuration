# modules/hermes-config.nix
#
# Single Source of Truth für Hermes Provider-/Model-/Auxiliary-Konfig.
# Wird von NixOS (*.hermes-agent.nix) und Darwin (home/darwin.nix) importiert —
# Änderungen hier wirken auf alle Hosts.
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
#   NOUS_API_KEY       — nativer nous-Plugin (built-in, model_catalog restricted).
#   CUSTOM_ZAI_KEY     — openai-compat routing zu api.z.ai/api/paas/v4.
#   CUSTOM_OPENMODEL_KEY — anthropic-compat routing zu api.openmodel.ai/v1.
#   KEIN ZAI_API_KEY / OPENMODEL_API_KEY / OPENAI_API_KEY —
#     damit Section 1/2 keine built-in zai/openai Einträge zeigt.
{ secrets }:

let
  apiKeys = import (secrets + "/hermes-api.nix");

  # CUSTOM_*-Namen statt nativer Env-Vars, damit built-in Provider-Checks nicht matchen.
  envKeys = {
    NOUS_API_KEY          = apiKeys.NOUS_API_KEY;
    CUSTOM_ZAI_KEY        = apiKeys.ZAI_API_KEY;
    CUSTOM_OPENMODEL_KEY  = apiKeys.OPENMODEL_API_KEY;
    API_SERVER_KEY        = apiKeys.API_SERVER_KEY;
  };

  # custom_providers (Section 4) — openai-compat Layer
  customProviders = [
    {
      name = "ollama-local";
      base_url = "http://localhost:11434/v1";
      discover_models = false;
      models = [ "vibethinker" ];
    }
    {
      name = "Z.AI Selection";
      base_url = "https://api.z.ai/api/coding/paas/v4";
      key_env = "CUSTOM_ZAI_KEY";
      discover_models = false;
      models = [ "glm-5.2" "glm-5.1" "glm-5v-turbo" "glm-4.5-air" ];
    }
  ];

  # providers (Section 3) — openmodell (anthropic-messages compat)
  userProviders = {
    openmodell = {
      name = "openmodell";
      base_url = "https://api.openmodel.ai/v1";
      key_env = "CUSTOM_OPENMODEL_KEY";
      transport = "anthropic_messages";
      discover_models = false;
      models = [ "deepseek-v4-flash" ];
    };
  };

  # model.models — Routing-Tabelle: Modellname → Provider + Credentials
  modelRouting = {
    # ollama (openai-compat)
    vibethinker = {
      provider = "openai";
      base_url = "http://localhost:11434/v1";
    };

    # z.ai (openai-compat — /api/paas/v4)
    "glm-5.2"       = { provider = "openai"; base_url = "https://api.z.ai/api/coding/paas/v4"; api_key_env = "CUSTOM_ZAI_KEY"; };
    "glm-5.1"       = { provider = "openai"; base_url = "https://api.z.ai/api/coding/paas/v4"; api_key_env = "CUSTOM_ZAI_KEY"; };
    "glm-5v-turbo"  = { provider = "openai"; base_url = "https://api.z.ai/api/coding/paas/v4"; api_key_env = "CUSTOM_ZAI_KEY"; };
    "glm-4.5-air"   = { provider = "openai"; base_url = "https://api.z.ai/api/coding/paas/v4"; api_key_env = "CUSTOM_ZAI_KEY"; };

    # Nous (natives Plugin — model_catalog restricted)
    "openrouter/owl-alpha"         = { provider = "nous"; };
    "deepseek/deepseek-v4-flash"   = { provider = "nous"; };
    "qwen/qwen3.7-plus"            = { provider = "nous"; };
    "minimax/minimax-m3"           = { provider = "nous"; };
    "stepfun/step-3.7-flash:free"  = { provider = "nous"; };
    "google/gemma-4-31b-it"        = { provider = "nous"; };
    "tencent/hy3-preview"          = { provider = "nous"; };

    # openmodel.ai (anthropic-messages compat — custom provider in `providers`).
    # Routing muss den PROVIDER-NAMEN referenzieren ("openmodell"), nicht den
    # Transport ("anthropic_messages"); sonst faellt hermes auf den built-in
    # `anthropic` Plugin zurueck, dessen Default-Base-URL api.anthropic.com ist.
    "deepseek-v4-flash" = {
      provider = "openmodell";
      base_url = "https://api.openmodel.ai/v1";
      api_key_env = "CUSTOM_OPENMODEL_KEY";
    };
  };

  # auxiliary — welche Modelle für Hintergrundaufgaben.
  # Auxiliary-Initialisierung BYPASSED die model.models Routing-Tabelle:
  # jedes Feld hier muss vollstaendig (provider + base_url + api_key_env)
  # sein. Ohne explizites api_key_env fallt der openai-compat Plugin auf
  # OPENAI_API_KEY zurueck, was fuer Z.AI-Endpoints der falsche Key ist
  # und in 401/403 fuehrt.
  auxiliary = {
    vision             = { provider = "openai"; base_url = "https://api.z.ai/api/coding/paas/v4"; api_key_env = "CUSTOM_ZAI_KEY"; model = "glm-5v-turbo"; timeout = 120; };
    web_extract        = { provider = "openai"; base_url = "https://api.z.ai/api/coding/paas/v4"; api_key_env = "CUSTOM_ZAI_KEY"; model = "glm-5.2";      timeout = 360; };
    compression        = { provider = "openai"; base_url = "https://api.z.ai/api/coding/paas/v4"; api_key_env = "CUSTOM_ZAI_KEY"; model = "glm-4.5-air";  timeout = 120; };
    skills_hub         = { provider = "openai"; base_url = "https://api.z.ai/api/coding/paas/v4"; api_key_env = "CUSTOM_ZAI_KEY"; model = "glm-4.5-air";  timeout = 30;  };
    approval           = { provider = "openai"; base_url = "https://api.z.ai/api/coding/paas/v4"; api_key_env = "CUSTOM_ZAI_KEY"; model = "glm-5.2";      timeout = 30;  };
    mcp                = { provider = "openai"; base_url = "https://api.z.ai/api/coding/paas/v4"; api_key_env = "CUSTOM_ZAI_KEY"; model = "glm-4.5-air";  timeout = 30;  };
    title_generation   = { provider = "openai"; base_url = "https://inference-api.nousresearch.com/v1"; api_key_env = "NOUS_API_KEY"; model = "google/gemma-4-31b-it"; timeout = 30;  };
    triage_specifier   = { provider = "openai"; base_url = "https://api.z.ai/api/coding/paas/v4"; api_key_env = "CUSTOM_ZAI_KEY"; model = "glm-5.1";      timeout = 120; };
    kanban_decomposer  = { provider = "openai"; base_url = "https://api.z.ai/api/coding/paas/v4"; api_key_env = "CUSTOM_ZAI_KEY"; model = "glm-5.1";      timeout = 180; };
    curator            = { provider = "openai"; base_url = "https://api.z.ai/api/coding/paas/v4"; api_key_env = "CUSTOM_ZAI_KEY"; model = "glm-4.5-air";  timeout = 600; };
    profile_describer  = { provider = "openai"; base_url = "https://api.z.ai/api/coding/paas/v4"; api_key_env = "CUSTOM_ZAI_KEY"; model = "glm-4.5-air";  timeout = 60;  };
  };

  # model_catalog — nous-Restriktion auf eigenes JSON
  model_catalog = {
    enabled = true;
    ttl_hours = 24;
    providers.nous.url = "https://raw.githubusercontent.com/Jannis789/nixos-configuration/master/model-catalog.json";
  };

  # compression defaults
  compression = {
    enabled = true;
    threshold = 0.50;
    target_ratio = 0.20;
  };

  # Vollständiger settings-Attrset für hermes-agent config.yaml
  hermesConfig = {
    model = {
      default = "deepseek-v4-flash";
      provider = "auto";
      models = modelRouting;
    };
    custom_providers = customProviders;
    providers = userProviders;
    inherit model_catalog auxiliary compression;
  };
in
{
  inherit envKeys hermesConfig;
}
