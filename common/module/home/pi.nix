{ config, lib, pkgs, ... }:
{
  # pi-coding-agent: damit du mit mir schreiben kannst
  programs.pi-coding-agent = {
    enable = true;
    settings = {
      lastChangelogVersion = "0.80.10";
      theme = "dark";
      defaultProvider = "nous";
      # nous-interface hat kein Modell-Catalog (auto model find); Default = erster Eintrag
      defaultModel = "~deepseek/deepseek-v4-flash-latest";
    };
    models = {
      provider = "nous";
      baseUrl = "https://inference-api.nousresearch.com/v1";
      api = "openai-completions";
      apiKey = "$NOUS_API_KEY"; # aus secrets.nix → home.sessionVariables
      models = [
        "~deepseek/deepseek-v4-flash-latest"
        "minimax-m3"
      ];
    };
  };
}
