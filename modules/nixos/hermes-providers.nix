# modules/nixos/hermes-providers.nix
#
# Provider-zu-Modellen-Katalog. Wird von modules/nixos/hermes-agent.nix
# ueber `import ./hermes-providers.nix` konsumiert und in das
# hermes-agent-Schema `settings.model.models.<namespace>` geflattet.
#
# Schema pro Provider:
#   provider    : identifier aus hermes-agent's provider-registry
#                 ("nous", "zai", "openai" als openai-compat layer)
#   base_url    : OPTIONAL — nur fuer openai-compat (ollama, openmodel.ai)
#                 noetig. Default = null.
#   api_key_env : Name der Env-Variable, aus der das Token kommt. Wird
#                 ueblicherweise aus secrets/hermes-api.nix ueber
#                 systemd.services.hermes-agent.environment + home.sessionVariables
#                 in den laufenden Prozess injiziert.
#   models      : Liste der Modellnamen *genau so*, wie sie der Provider
#                 kennt (Groß-/Kleinschreibung wird beibehalten — das
#                 ist hier Vertrag zwischen NixOS-Konfig und dem zur
#                 Laufzeit aktiven provider-plugin).
#
# Katalog-Inhalt ist explizit auf die User-Vorgabe gemappt:
#   ollama   → vibethinker
#   zai      → glm-5.2, glm-5.1, glm-5v-turbo, glm-4.5-flash
#   nous     → openrouter/owl-alpha, deepseek/deepseek-v4-flash,
#              qwen/qwen3.7-plus, minimax/minimax-m3, stepfun/step-3.7-flash:free,
#              google/gemma-4-31b-it, tencent/hy3-preview
#   openmodel → deepseek-v4-flash (anthropic-compat, /v1/messages)
#
{
  # ── ollama (lokal, OpenAI-compat Layer auf Port 11434) ────────────────
  # Provider-Plugin "openai" mit base_url override. Kein echtes Token
  # noetig; OPENAI_API_KEY wird trotzdem gesetzt (ollama ignoriert es
  # standardmaessig) — bewahrt Symmetrie zum openmodel-Eintrag.
  ollama = {
    provider = "openai";
    base_url = "http://localhost:11434/v1";
    api_key_env = "OPENAI_API_KEY";
    models = [ "vibethinker" ];
  };

  # ── zai (Zhipu, Z.AI) ─────────────────────────────────────────────────
  # Native hermes-agent "zai"-Plugin liest GLM_API_KEY automatisch.
  zai = {
    provider = "zai";
    api_key_env = "GLM_API_KEY";
    models = [
      "glm-5.2"
      "glm-5.1"
      "glm-5v-turbo"
      "glm-4.5-flash"
    ];
  };

  # ── nous (NousResearch / OpenRouter-Katalog) ─────────────────────────
  # Native hermes-agent "nous"-Plugin liest NOUS_API_KEY automatisch.
  nous = {
    provider = "nous";
    api_key_env = "NOUS_API_KEY";
    models = [
      "openrouter/owl-alpha"
      "deepseek/deepseek-v4-flash"
      "qwen/qwen3.7-plus"
      "minimax/minimax-m3"
      "stepfun/step-3.7-flash:free"
      "google/gemma-4-31b-it"
      "tencent/hy3-preview"
    ];
  };

  # ── openmodel.ai (Anthropic-compat /v1/messages) ──────────────────────
  # Kollidiert im Modellnamen "deepseek-v4-flash" mit nous — wird im
  # hermes-agent.nix-flatten durch Namespace-Prefix disambiguiert.
  openmodel = {
    provider = "anthropic";
    base_url = "https://api.openmodel.ai/v1";
    api_key_env = "OPENMODEL_API_KEY";
    models = [ "deepseek-v4-flash" ];
  };
}
