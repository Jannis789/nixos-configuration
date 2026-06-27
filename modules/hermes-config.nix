# Single source of truth for Hermes provider/model/auxiliary config.
# Imported by NixOS (hermes-agent.nix) and Darwin (home/darwin.nix).
# API keys via secrets submodule — NOUS_API_KEY, CUSTOM_ZAI_KEY, CUSTOM_OPENMODEL_KEY, CLOUDFLARE_API_KEY.
{ secrets }:

let
  apiKeys = import (secrets + "/hermes-api.nix");

  # Custom env var names prevent built-in provider detection (no ZAI_API_KEY / OPENAI_API_KEY)
  envKeys = {
    NOUS_API_KEY          = apiKeys.NOUS_API_KEY;
    CUSTOM_ZAI_KEY        = apiKeys.ZAI_API_KEY;
    CUSTOM_OPENMODEL_KEY  = apiKeys.OPENMODEL_API_KEY;
    API_SERVER_KEY        = apiKeys.API_SERVER_KEY;
    CLOUDFLARE_API_KEY    = apiKeys.CLOUDFLARE_API_KEY;
  };

  # openai-compat custom providers
  cfBaseUrl = "https://api.cloudflare.com/client/v4/accounts/b37ac61cb7df4a6909bb62aa67784c81/ai/v1";

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
    {
      name = "Nous Inference";
      base_url = "https://inference-api.nousresearch.com/v1";
      key_env = "NOUS_API_KEY";
      discover_models = false;
      models = [
        "google/gemma-4-31b-it"
        "nemotron-3-super-120b-a12b"
        "qwen/qwen3-next-80b-a3b-instruct"
      ];
    }
    {
      name = "Cloudflare Workers AI";
      base_url = cfBaseUrl;
      key_env = "CLOUDFLARE_API_KEY";
      discover_models = false;
      models = [
        "@cf/meta/llama-3.3-70b-instruct-fp8-fast"
        "@cf/openai/gpt-oss-120b"
        "@cf/moonshotai/kimi-k2.6"
        "@cf/nvidia/nemotron-3-120b-a12b"
        "@cf/qwen/qwen3-30b-a3b-fp8"
        "@cf/zai-org/glm-4.7-flash"
        "@cf/meta/llama-4-scout-17b-16e-instruct"
      ];
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

    # Nous Inference API
    "google/gemma-4-31b-it"        = { provider = "openai"; base_url = "https://inference-api.nousresearch.com/v1"; api_key_env = "NOUS_API_KEY"; };
    "nemotron-3-super-120b-a12b"   = { provider = "openai"; base_url = "https://inference-api.nousresearch.com/v1"; api_key_env = "NOUS_API_KEY"; };
    "qwen/qwen3-next-80b-a3b-instruct" = { provider = "openai"; base_url = "https://inference-api.nousresearch.com/v1"; api_key_env = "NOUS_API_KEY"; };

    # Cloudflare Workers AI
    "@cf/meta/llama-3.3-70b-instruct-fp8-fast" = { provider = "openai"; base_url = cfBaseUrl; api_key_env = "CLOUDFLARE_API_KEY"; };
    "@cf/openai/gpt-oss-120b"                    = { provider = "openai"; base_url = cfBaseUrl; api_key_env = "CLOUDFLARE_API_KEY"; };
    "@cf/moonshotai/kimi-k2.6"                   = { provider = "openai"; base_url = cfBaseUrl; api_key_env = "CLOUDFLARE_API_KEY"; };
    "@cf/nvidia/nemotron-3-120b-a12b"            = { provider = "openai"; base_url = cfBaseUrl; api_key_env = "CLOUDFLARE_API_KEY"; };
    "@cf/qwen/qwen3-30b-a3b-fp8"                 = { provider = "openai"; base_url = cfBaseUrl; api_key_env = "CLOUDFLARE_API_KEY"; };
    "@cf/zai-org/glm-4.7-flash"                  = { provider = "openai"; base_url = cfBaseUrl; api_key_env = "CLOUDFLARE_API_KEY"; };
    "@cf/meta/llama-4-scout-17b-16e-instruct"    = { provider = "openai"; base_url = cfBaseUrl; api_key_env = "CLOUDFLARE_API_KEY"; };

    # openmodel.ai anthropic-messages — must reference provider name, not transport
    # (routing uses "openmodell", not "anthropic_messages")
    "deepseek-v4-flash" = {
      provider = "openmodell";
      base_url = "https://api.openmodel.ai/v1";
      api_key_env = "CUSTOM_OPENMODEL_KEY";
    };
  };

  # Auxiliary models via Cloudflare Workers AI free tier (CLOUDFLARE_API_KEY)
  # Bypass model.models routing — each entry must be self-contained
  auxiliary = {
    vision             = { provider = "openai"; base_url = "https://inference-api.nousresearch.com/v1"; api_key_env = "NOUS_API_KEY"; model = "google/gemma-4-31b-it"; timeout = 120; };
    web_extract        = { provider = "openai"; base_url = cfBaseUrl; api_key_env = "CLOUDFLARE_API_KEY"; model = "@cf/nvidia/nemotron-3-120b-a12b";            timeout = 360; };
    compression        = { provider = "openai"; base_url = cfBaseUrl; api_key_env = "CLOUDFLARE_API_KEY"; model = "@cf/nvidia/nemotron-3-120b-a12b";            timeout = 120; };
    skills_hub         = { provider = "openai"; base_url = cfBaseUrl; api_key_env = "CLOUDFLARE_API_KEY"; model = "@cf/zai-org/glm-4.7-flash";                     timeout = 30;  };
    approval           = { provider = "openai"; base_url = cfBaseUrl; api_key_env = "CLOUDFLARE_API_KEY"; model = "@cf/meta/llama-3.3-70b-instruct-fp8-fast"; timeout = 30;  };
    mcp                = { provider = "openai"; base_url = cfBaseUrl; api_key_env = "CLOUDFLARE_API_KEY"; model = "@cf/zai-org/glm-4.7-flash";                     timeout = 30;  };
    title_generation   = { provider = "openai"; base_url = cfBaseUrl; api_key_env = "CLOUDFLARE_API_KEY"; model = "@cf/zai-org/glm-4.7-flash";                     timeout = 30;  };
    triage_specifier   = { provider = "openai"; base_url = cfBaseUrl; api_key_env = "CLOUDFLARE_API_KEY"; model = "@cf/nvidia/nemotron-3-120b-a12b";            timeout = 120; };
    kanban_decomposer  = { provider = "openai"; base_url = cfBaseUrl; api_key_env = "CLOUDFLARE_API_KEY"; model = "@cf/nvidia/nemotron-3-120b-a12b";            timeout = 180; };
    curator            = { provider = "openai"; base_url = cfBaseUrl; api_key_env = "CLOUDFLARE_API_KEY"; model = "@cf/nvidia/nemotron-3-120b-a12b";            timeout = 600; };
    profile_describer  = { provider = "openai"; base_url = cfBaseUrl; api_key_env = "CLOUDFLARE_API_KEY"; model = "@cf/zai-org/glm-4.7-flash";                     timeout = 60;  };
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
    inherit auxiliary compression;
  };
in
{
  inherit envKeys hermesConfig;
}
