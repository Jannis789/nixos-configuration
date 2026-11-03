{
  config,
  lib,
  pkgs,
  goosePkg,
  ...
}:
{
  # Host-overridebare Goose-Defaults (Spiegel von modules/home/pi.nix).
  # Setzt den nativen Z.AI Coding Plan Provider (goose >= v1.53.0) als
  # Standard. Andere Hosts koennen defaultProvider/defaultModel tauschen,
  # ohne den Rest zu duplizieren.
  options.gooseAgent = {
    defaultProvider = lib.mkOption {
      type = lib.types.str;
      default = "zai_coding_plan";
    };
    defaultModel = lib.mkOption {
      type = lib.types.str;
      default = "glm-5.3";
    };
  };

  config = {
    # goose-cli 1.53.0 aus llm-agents.nix (ueber flake.nix -> extraSpecialArgs
    # als goosePkg durchgereicht). ZAI_CODING_PLAN_API_KEY + OPENCODE_API_KEY
    # kommen aus hosts/.../home.nix (home.sessionVariables, secrets).
    home.packages = [ goosePkg ];

    # Nativer Z.AI Coding Plan Provider als Default. Andere Provider per
    # Laufzeit-Override: GOOSE_PROVIDER=... GOOSE_MODEL=...
    # GOOSE_PROVIDER/GOOSE_MODEL = Default-Provider.Model. API-Keys liegen
    # zentral in hosts/.../home.nix: ZAI_CODING_PLAN_API_KEY (= seams.ZAI_API_KEY)
    # und OPENCODE_API_KEY (fuer custom_opencode).
    home.sessionVariables = {
      GOOSE_PROVIDER = config.gooseAgent.defaultProvider;
      GOOSE_MODEL = config.gooseAgent.defaultModel;
    };

    # pi-Provider als Goose-Custom-Provider spiegeln. JSON-Schema:
    # DeclarativeProviderConfig, geladen aus ~/.config/goose/custom_providers/{name}.json.
    #
    # custom_zai: FALLBACK fuer den nativen zai_coding_plan (nutzt denselben
    # paas/v4-Endpoint). Harmlos parallel; wenn v1.53.0 den nativen Provider
    # erkennt, ist dieser Eintrag redundant.
    home.file.".config/goose/custom_providers/custom_zai.json".source =
      ../../assets/goose/custom_zai.json;
    # custom_opencode: offener Code-Go-Gateway (kein nativer Provider).
    # Host-Listing bestaetigte die Model-Liste (inkl. deepseek); die
    # "Global regions"-Freigabe ist ein Konto-/Workspace-Setting.
    home.file.".config/goose/custom_providers/custom_opencode.json".source =
      ../../assets/goose/custom_opencode.json;
  };
}
