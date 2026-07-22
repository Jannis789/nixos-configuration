# Hermes provider/model/auxiliary config + API-key env mapping.
{ secrets }:

let
  apiKeys = import (secrets + "/hermes-api.nix");

  envKeys = {
    CUSTOM_NOUS_KEY        = apiKeys.NOUS_API_KEY;
    CUSTOM_ZAI_KEY         = apiKeys.ZAI_API_KEY;
    CUSTOM_OPENMODEL_KEY   = apiKeys.OPENMODEL_API_KEY;
    CUSTOM_OPENROUTER_KEY  = apiKeys.OPENROUTER_API_KEY;
    CUSTOM_CLOUDFLARE_KEY  = apiKeys.CLOUDFLARE_API_KEY;
    CUSTOM_OPENCODE_KEY    = apiKeys.OPENCODE_API_KEY;
    CUSTOM_NVIDIA_KEY      = apiKeys.NVIDIA_API_KEY;
    API_SERVER_KEY         = apiKeys.API_SERVER_KEY;
    NOUS_API_KEY           = apiKeys.NOUS_API_KEY;
  };

  orBaseUrl = "https://openrouter.ai/api/v1";

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
      name = "OpenRouter Free";
      base_url = orBaseUrl;
      key_env = "CUSTOM_OPENROUTER_KEY";
      discover_models = false;
      models = [
        "openrouter/owl-alpha"
        "google/gemma-4-31b-it:free"
        "cohere/north-mini-code:free"
      ];
    }
    {
      name = "OpenCode Zen";
      base_url = "https://opencode.ai/zen/v1";
      key_env = "CUSTOM_OPENCODE_KEY";
      discover_models = false;
      models = [
        "deepseek-v4-flash-free"
        "qwen3.6-plus-free"
        "big-pickle-free"
        "mimo-v2.5-free"
        "nemotron-3-ultra-free"
        "north-mini-code-free"
      ];
    }
    {
      name = "Cloudflare Workers AI";
      base_url = "https://api.cloudflare.com/client/v4/accounts/b37ac61cb7df4a6909bb62aa67784c81/ai/v1";
      key_env = "CUSTOM_CLOUDFLARE_KEY";
      discover_models = false;
      max_tokens = 32000;
      models = [
        "@cf/meta/llama-3.3-70b-instruct-fp8-fast"
        "@cf/meta/llama-4-scout-17b-16e-instruct"
        "@cf/moonshotai/kimi-k2.6"
        "@cf/nvidia/nemotron-3-120b-a12b"
        "@cf/openai/gpt-oss-120b"
        "@cf/openai/gpt-oss-20b"
        "@cf/qwen/qwen3-30b-a3b-fp8"
        "@cf/qwen/qwq-32b"
        "@cf/zai-org/glm-4.7-flash"
        "@cf/zai-org/glm-5.2"
        "@cf/google/gemma-4-26b-a4b-it"
        "@cf/mistralai/mistral-small-3.1-24b-instruct"
        "@cf/deepseek-ai/deepseek-r1-distill-qwen-32b"
        "@cf/meta/llama-3.1-8b-instruct-fp8"
        "@cf/meta/llama-3.2-11b-vision-instruct"
        "@cf/meta/llama-3.2-3b-instruct"
        "@cf/meta/llama-3.2-1b-instruct"
      ];
    }
    {
      name = "NVIDIA";
      base_url = "https://integrate.api.nvidia.com/v1";
      key_env = "CUSTOM_NVIDIA_KEY";
      discover_models = false;
      models = [
        "minimaxai/minimax-m3"
        "z-ai/glm-5.2"
        "nvidia/nemotron-3-ultra-550b-a55b"
        "deepseek-ai/deepseek-v4-flash"
        "deepseek-ai/deepseek-v4-pro"
        "thinkingmachines/inkling"
      ];
    }
  ];

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

  modelRouting = {
    vibethinker = {
      provider = "openai";
      base_url = "http://localhost:11434/v1";
    };

    "glm-5.2"       = { provider = "openai"; base_url = "https://api.z.ai/api/coding/paas/v4"; api_key_env = "CUSTOM_ZAI_KEY"; };
    "glm-5.1"       = { provider = "openai"; base_url = "https://api.z.ai/api/coding/paas/v4"; api_key_env = "CUSTOM_ZAI_KEY"; };
    "glm-5v-turbo"  = { provider = "openai"; base_url = "https://api.z.ai/api/coding/paas/v4"; api_key_env = "CUSTOM_ZAI_KEY"; };
    "glm-4.5-air"   = { provider = "openai"; base_url = "https://api.z.ai/api/coding/paas/v4"; api_key_env = "CUSTOM_ZAI_KEY"; };

    "openrouter/owl-alpha"              = { provider = "openai"; base_url = orBaseUrl; api_key_env = "CUSTOM_OPENROUTER_KEY"; };
    "google/gemma-4-31b-it:free"        = { provider = "openai"; base_url = orBaseUrl; api_key_env = "CUSTOM_OPENROUTER_KEY"; };
    "cohere/north-mini-code:free"       = { provider = "openai"; base_url = orBaseUrl; api_key_env = "CUSTOM_OPENROUTER_KEY"; };

    "deepseek-v4-flash" = {
      provider = "openmodell";
      base_url = "https://api.openmodel.ai/v1";
      api_key_env = "CUSTOM_OPENMODEL_KEY";
    };

    "deepseek-v4-flash-free"  = { provider = "OpenCode Zen"; base_url = "https://opencode.ai/zen/v1"; api_key_env = "CUSTOM_OPENCODE_KEY"; };
    "qwen3.6-plus-free"       = { provider = "OpenCode Zen"; base_url = "https://opencode.ai/zen/v1"; api_key_env = "CUSTOM_OPENCODE_KEY"; };
    "big-pickle-free"         = { provider = "OpenCode Zen"; base_url = "https://opencode.ai/zen/v1"; api_key_env = "CUSTOM_OPENCODE_KEY"; };
    "mimo-v2.5-free"          = { provider = "OpenCode Zen"; base_url = "https://opencode.ai/zen/v1"; api_key_env = "CUSTOM_OPENCODE_KEY"; };
    "nemotron-3-ultra-free"   = { provider = "OpenCode Zen"; base_url = "https://opencode.ai/zen/v1"; api_key_env = "CUSTOM_OPENCODE_KEY"; };
    "north-mini-code-free"    = { provider = "OpenCode Zen"; base_url = "https://opencode.ai/zen/v1"; api_key_env = "CUSTOM_OPENCODE_KEY"; };

    # NVIDIA Build API (gratis tier)
    "minimaxai/minimax-m3"              = { provider = "NVIDIA"; base_url = "https://integrate.api.nvidia.com/v1"; api_key_env = "CUSTOM_NVIDIA_KEY"; };
    "z-ai/glm-5.2"                      = { provider = "NVIDIA"; base_url = "https://integrate.api.nvidia.com/v1"; api_key_env = "CUSTOM_NVIDIA_KEY"; };
    "nvidia/nemotron-3-ultra-550b-a55b"  = { provider = "NVIDIA"; base_url = "https://integrate.api.nvidia.com/v1"; api_key_env = "CUSTOM_NVIDIA_KEY"; };
    "deepseek-ai/deepseek-v4-flash"     = { provider = "NVIDIA"; base_url = "https://integrate.api.nvidia.com/v1"; api_key_env = "CUSTOM_NVIDIA_KEY"; };
    "deepseek-ai/deepseek-v4-pro"       = { provider = "NVIDIA"; base_url = "https://integrate.api.nvidia.com/v1"; api_key_env = "CUSTOM_NVIDIA_KEY"; };
    "thinkingmachines/inkling"           = { provider = "NVIDIA"; base_url = "https://integrate.api.nvidia.com/v1"; api_key_env = "CUSTOM_NVIDIA_KEY"; };
  };

  auxiliary = {
    compression        = { provider = "openai"; base_url = orBaseUrl; api_key_env = "CUSTOM_OPENROUTER_KEY"; model = "openrouter/owl-alpha";            timeout = 120; };
    vision             = { provider = "openai"; base_url = orBaseUrl; api_key_env = "CUSTOM_OPENROUTER_KEY"; model = "google/gemma-4-31b-it:free";      timeout = 120; };
    web_extract        = { provider = "openai"; base_url = orBaseUrl; api_key_env = "CUSTOM_OPENROUTER_KEY"; model = "openrouter/owl-alpha";            timeout = 360; };
    skills_hub         = { provider = "openai"; base_url = orBaseUrl; api_key_env = "CUSTOM_OPENROUTER_KEY"; model = "cohere/north-mini-code:free";     timeout = 30;  };
    approval           = { provider = "openai"; base_url = orBaseUrl; api_key_env = "CUSTOM_OPENROUTER_KEY"; model = "google/gemma-4-31b-it:free";      timeout = 30;  };
    mcp                = { provider = "openai"; base_url = orBaseUrl; api_key_env = "CUSTOM_OPENROUTER_KEY"; model = "cohere/north-mini-code:free";     timeout = 30;  };
    title_generation   = { provider = "openai"; base_url = orBaseUrl; api_key_env = "CUSTOM_OPENROUTER_KEY"; model = "openrouter/owl-alpha";            timeout = 30;  };
    triage_specifier   = { provider = "openai"; base_url = orBaseUrl; api_key_env = "CUSTOM_OPENROUTER_KEY"; model = "google/gemma-4-31b-it:free";      timeout = 120; };
    kanban_decomposer  = { provider = "openai"; base_url = orBaseUrl; api_key_env = "CUSTOM_OPENROUTER_KEY"; model = "google/gemma-4-31b-it:free";      timeout = 180; };
    curator            = { provider = "openai"; base_url = orBaseUrl; api_key_env = "CUSTOM_OPENROUTER_KEY"; model = "openrouter/owl-alpha";            timeout = 600; };
    profile_describer  = { provider = "openai"; base_url = orBaseUrl; api_key_env = "CUSTOM_OPENROUTER_KEY"; model = "cohere/north-mini-code:free";     timeout = 60;  };
  };

  compression = {
    enabled = true;
    threshold = 0.50;
    target_ratio = 0.20;
  };

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
