# Single source of truth for Hermes provider/model/auxiliary config.
# Imported by NixOS (hermes-agent.nix) and Darwin (home/darwin.nix).
# API keys via secrets submodule — NOUS_API_KEY, CUSTOM_ZAI_KEY, CUSTOM_OPENMODEL_KEY.
{ secrets }:

let
  apiKeys = import (secrets + "/hermes-api.nix");

  # Custom env var names prevent built-in provider detection (no ZAI_API_KEY / OPENAI_API_KEY)
  envKeys = {
    NOUS_API_KEY          = apiKeys.NOUS_API_KEY;
    CUSTOM_ZAI_KEY        = apiKeys.ZAI_API_KEY;
    CUSTOM_OPENMODEL_KEY  = apiKeys.OPENMODEL_API_KEY;
    API_SERVER_KEY        = apiKeys.API_SERVER_KEY;
  };

  # openai-compat custom providers
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

  # anthropic-messages compat provider (openmodell)
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

  # model.models routing: model name → provider + credentials
  modelRouting = {
    vibethinker = {
      provider = "openai";
      base_url = "http://localhost:11434/v1";
    };

    # z.ai openai-compat
    "glm-5.2"       = { provider = "openai"; base_url = "https://api.z.ai/api/coding/paas/v4"; api_key_env = "CUSTOM_ZAI_KEY"; };
    "glm-5.1"       = { provider = "openai"; base_url = "https://api.z.ai/api/coding/paas/v4"; api_key_env = "CUSTOM_ZAI_KEY"; };
    "glm-5v-turbo"  = { provider = "openai"; base_url = "https://api.z.ai/api/coding/paas/v4"; api_key_env = "CUSTOM_ZAI_KEY"; };
    "glm-4.5-air"   = { provider = "openai"; base_url = "https://api.z.ai/api/coding/paas/v4"; api_key_env = "CUSTOM_ZAI_KEY"; };

    # Nous (model_catalog restricted)
    "openrouter/owl-alpha"         = { provider = "nous"; };
    "deepseek/deepseek-v4-flash"   = { provider = "nous"; };
    "qwen/qwen3.7-plus"            = { provider = "nous"; };
    "minimax/minimax-m3"           = { provider = "nous"; };
    "stepfun/step-3.7-flash:free"  = { provider = "nous"; };
    "google/gemma-4-31b-it"        = { provider = "nous"; };
    "tencent/hy3-preview"          = { provider = "nous"; };

    # openmodel.ai anthropic-messages — must reference provider name, not transport
    # (routing uses "openmodell", not "anthropic_messages")
    "deepseek-v4-flash" = {
      provider = "openmodell";
      base_url = "https://api.openmodel.ai/v1";
      api_key_env = "CUSTOM_OPENMODEL_KEY";
    };
  };

  # Auxiliary models via OpenRouter free tier (NOUS_API_KEY)
  # Bypass model.models routing — each entry must be self-contained
  auxiliary = {
    vision             = { provider = "openai"; base_url = "https://openrouter.ai/api/v1"; api_key_env = "NOUS_API_KEY"; model = "google/gemma-4-31b-it:free";               timeout = 120; };
    web_extract        = { provider = "openai"; base_url = "https://openrouter.ai/api/v1"; api_key_env = "NOUS_API_KEY"; model = "openrouter/owl-alpha";                     timeout = 360; };
    compression        = { provider = "openai"; base_url = "https://openrouter.ai/api/v1"; api_key_env = "NOUS_API_KEY"; model = "openrouter/owl-alpha";                     timeout = 120; };
    skills_hub         = { provider = "openai"; base_url = "https://openrouter.ai/api/v1"; api_key_env = "NOUS_API_KEY"; model = "cohere/north-mini-code:free";              timeout = 30;  };
    approval           = { provider = "openai"; base_url = "https://openrouter.ai/api/v1"; api_key_env = "NOUS_API_KEY"; model = "qwen/qwen3-next-80b-a3b-instruct:free";     timeout = 30;  };
    mcp                = { provider = "openai"; base_url = "https://openrouter.ai/api/v1"; api_key_env = "NOUS_API_KEY"; model = "cohere/north-mini-code:free";              timeout = 30;  };
    title_generation   = { provider = "openai"; base_url = "https://openrouter.ai/api/v1"; api_key_env = "NOUS_API_KEY"; model = "openrouter/owl-alpha";                     timeout = 30;  };
    triage_specifier   = { provider = "openai"; base_url = "https://openrouter.ai/api/v1"; api_key_env = "NOUS_API_KEY"; model = "qwen/qwen3-next-80b-a3b-instruct:free";     timeout = 120; };
    kanban_decomposer  = { provider = "openai"; base_url = "https://openrouter.ai/api/v1"; api_key_env = "NOUS_API_KEY"; model = "qwen/qwen3-next-80b-a3b-instruct:free";     timeout = 180; };
    curator            = { provider = "openai"; base_url = "https://openrouter.ai/api/v1"; api_key_env = "NOUS_API_KEY"; model = "openrouter/owl-alpha";                     timeout = 600; };
    profile_describer  = { provider = "openai"; base_url = "https://openrouter.ai/api/v1"; api_key_env = "NOUS_API_KEY"; model = "cohere/north-mini-code:free";              timeout = 60;  };
  };

  # model_catalog — restrict nous to custom JSON
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

  # Full settings attrset for hermes-agent config.yaml
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
