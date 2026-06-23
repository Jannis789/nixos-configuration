# modules/nixos/hermes-agent.nix
#
# Hermes-Agent NixOS Service. Der Service-Unit (`hermes-agent.service`)
# bekommt seine Env-Vars (API-Keys) direkt ueber
# `systemd.services.hermes-agent.environment` aus
# `secrets/hermes-api.nix` injiziert — kein .env-Zaunpfahl mehr.
#
# Das Modell-Catalog kommt aus `modules/nixos/hermes-providers.nix`,
# wird hier mittels lib.concatMapAttrs + lib.listToAttrs zu
# `settings.model.models.<namespace>` geflattet. Schema-Convention:
#   models.\"<provider-id>/<model-name>\" = { provider, base_url?, api_key_env }
#
# Auxiliary-Block referenziert die Modelle mit der exakten Schreibweise
# aus dem Katalog.
{ config, lib, pkgs, inputs, ... }:

let
  catalog = import ./hermes-providers.nix;
  # `inputs.secrets` ist ein `path:`-Flake-Input (siehe flake.nix).
  # Nix kopiert das Verzeichnis 1:1 in den Store, OHNE den
  # Git-Tracker des Submodul-Repos zu konsultieren. Damit ist
  # die untracked `hermes-api.nix` fuer die Flake-Eval sichtbar —
  # KEIN plaintext-Key muss in eine Git-History wandern.
  # Vorheriger Versuch mit `builtins.path` ist gescheitert, weil
  # `builtins.path` aus einem Flake-Kontext heraus denselben
  # Git-Tracker triggert wie plain `import`. `path:`-Inputs sind
  # die offizielle Nix-Workaround dafuer.
  apiKeys = import (inputs."private-keys" + "/hermes-api.nix");

  # Flatten per-provider Modellliste zu namespaced model.entries.
  # Key shape: "<provider-id>/<model-name>"; collision-safe weil
  # openmodel und nous beide "deepseek-v4-flash" exposen.
  modelsAttrs = lib.concatMapAttrs
    (providerId: cfg:
      lib.listToAttrs (map (modelName:
        lib.nameValuePair "${providerId}/${modelName}" (
          { provider = cfg.provider; api_key_env = cfg.api_key_env; }
          // lib.optionalAttrs (cfg ? base_url) { base_url = cfg.base_url; }
        )
      ) cfg.models)
    )
    catalog;
in
{
  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;

    settings = {
      # ── Modell ────────────────────────────────────────────────────────
      # `default` bleibt deepseek/deepseek-v4-flash (Nous/OpenRouter-Katalog).
      # `provider  = "auto"` haelt das Desktop-Dropdown offen fuer alle
      # Provider, der model.models-Block erweitert den Katalog nur —
      # OHNE ihn zu ersetzen oder einzelne Provider zu unterdruecken.
      # Per-model-Eintraege sind daher rein additiv.
      model = {
        default = "deepseek/deepseek-v4-flash";
        provider = "auto";
        models = modelsAttrs;
      };

      # ── Auxiliary Tasks ───────────────────────────────────────────────
      # Provider/Modell-Referenzen nutzen die exakte Schreibweise aus
      # modules/nixos/hermes-providers.nix (zai.<liste>, nous.<liste>).
      auxiliary = {
        # Vision: braucht Multimodal — glm-5v-turbo.
        vision      = { provider = "zai"; model = "glm-5v-turbo";   timeout = 120; };
        # Web-Extraktion: gutes Textverstehen, langer Timeout — glm-5.2.
        web_extract = { provider = "zai"; model = "glm-5.2";        timeout = 360; };
        # Context-Kompression: schnell genug — glm-4.5-flash.
        compression = { provider = "zai"; model = "glm-4.5-flash";  timeout = 120; };
        # Skill-Hub: lightweight, viele Calls — glm-4.5-flash.
        skills_hub  = { provider = "zai"; model = "glm-4.5-flash";  timeout = 30;  };
        # Command-Approval: Sicherheit, braucht Qualitaet — glm-5.2.
        approval    = { provider = "zai"; model = "glm-5.2";        timeout = 30;  };
        # MCP-Server-Op: lightweight — glm-4.5-flash.
        mcp         = { provider = "zai"; model = "glm-4.5-flash";  timeout = 30;  };
        # Session-Titel: gemma-4-31b-it ist im nous-Katalog und billig.
        title_generation = { provider = "nous"; model = "google/gemma-4-31b-it"; timeout = 30;  };
        # Triage: braucht Reasoning — glm-5.1.
        triage_specifier  = { provider = "zai";  model = "glm-5.1";       timeout = 120; };
        # Kanban-Task-Zerlegung: Reasoning — glm-5.1.
        kanban_decomposer = { provider = "zai";  model = "glm-5.1";       timeout = 180; };
        # Skill-Lifecycle Curator: lang, billig — glm-4.5-flash.
        curator           = { provider = "zai";  model = "glm-4.5-flash"; timeout = 600; };
        # Profil-Beschreibungen: schnell, einfach — glm-4.5-flash.
        profile_describer = { provider = "zai";  model = "glm-4.5-flash"; timeout = 60;  };
      };

      # ── Compression defaults ──────────────────────────────────────────
      compression = {
        enabled = true;
        threshold = 0.50;
        target_ratio = 0.20;
      };
    };
  };

  # API-Keys ueber die Upstream-Option `services.hermes-agent.environment`
  # (NICHT `systemd.services.X.environment`!). Upstream nix/nixosModules.nix
  # seeds diese Werte bei Aktivierung in `$HERMES_HOME/.env`, und
  # `hermes-agent` laedt sie zur Laufzeit via `load_hermes_dotenv()` — NICHT
  # ueber `Environment=` systemd-direktive. Caveat: landet im /nix/store
  # (mode 0444 auf single-user laptops offfentlich lesbar). Fuer sops-nix
  # spaeter ueber `services.hermes-agent.environmentFiles` migrierbar;
  # bis dahin akzeptieren wir das Risiko.
  services.hermes-agent.environment = apiKeys;
}
