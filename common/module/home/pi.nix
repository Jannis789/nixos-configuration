{ config, lib, pkgs, ... }:
{
  programs.pi-coding-agent = {
    enable = true;
    settings = {
      lastChangelogVersion = "0.80.10";
      theme = "dark";
      defaultProvider = "nous";
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
