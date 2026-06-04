{ config, lib, pkgs, ... }:

{
  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;

    settings = {
      model = "deepseek/deepseek-v4-flash";
      provider = "nous";

      # ── Auxiliary Tasks ──────────────────────────────────────────────────
      # Jeder Task kriegt das passende Z.AI-Modell: Flash/Air fuer
      # High-Throughput, Turbo fuer Qualitaet, 5V fuer Vision.
      auxiliary = {
        # Vision — braucht Multimodal
        vision = {
          provider = "zai";
          model = "GLM-5V-Turbo";
          timeout = 120;
        };

        # Web-Extraktion — braucht gutes Textverstaendnis
        web_extract = {
          provider = "zai";
          model = "GLM-5-Turbo";
          timeout = 360;
        };

        # Context-Kompression — Flash ist schnell genug
        compression = {
          provider = "zai";
          model = "GLM-4.7-Flash";
          timeout = 120;
        };

        # Skill-Hub-Abfragen — lightweight, 5 concurrency
        skills_hub = {
          provider = "zai";
          model = "GLM-4.5-Air";
          timeout = 30;
        };

        # Command-Approval — Sicherheit, braucht Qualitaet
        approval = {
          provider = "zai";
          model = "GLM-5-Turbo";
          timeout = 30;
        };

        # MCP-Server-Operationen — lightweight
        mcp = {
          provider = "zai";
          model = "GLM-4.5-Air";
          timeout = 30;
        };

        # Session-Titel generieren — fast egal, Air reicht
        title_generation = {
          provider = "zai";
          model = "GLM-4.5-Air";
          timeout = 30;
        };

        # Task-Triage/Spezifikation — braucht Reasoning
        triage_specifier = {
          provider = "zai";
          model = "GLM-5-Turbo";
          timeout = 120;
        };

        # Kanban-Task-Zerlegung — braucht Reasoning
        kanban_decomposer = {
          provider = "zai";
          model = "GLM-5-Turbo";
          timeout = 180;
        };

        # Skill-Lifecycle (Curator) — langlaufend, cheap
        curator = {
          provider = "zai";
          model = "GLM-4.5-Air";
          timeout = 600;
        };

        # Profil-Beschreibungen — schnell, einfach
        profile_describer = {
          provider = "zai";
          model = "GLM-4.5-AirX";
          timeout = 60;
        };
      };

      # ── Compression defaults ────────────────────────────────────────────
      compression = {
        enabled = true;
        threshold = 0.50;
        target_ratio = 0.20;
      };
    };

    environmentFiles = [
      "/home/jannis/Dokumente/nixos-configuration/secrets/hermes-env"
    ];
  };
}
