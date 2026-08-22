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
  };

  # models.json direkt mit korrektem Schema schreiben (das HM-Modul schreibt
  # es flach → pi-Fehler "must have required properties providers").
  home.file.".pi/agent/models.json".text = builtins.toJSON {
    providers.nous = {
      baseUrl = "https://inference-api.nousresearch.com/v1";
      api = "openai-completions";
      apiKey = "$NOUS_API_KEY"; # aus home.sessionVariables (secrets.nix)
      models = [
        { id = "~deepseek/deepseek-v4-flash-latest"; }
        { id = "minimax-m3"; }
      ];
    };
  };
}
