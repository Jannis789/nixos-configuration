{ pkgs, ... }:
{
  home.username = "jannis";
  home.homeDirectory = "/home/jannis";
  home.stateVersion = "26.05";

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
        "laguna-s-2.1:free"
        "laguna-xs-2.1:free"
        "step-3.7-flash:free"
        "inclusionai/ling-3.0-flash:free"
        "~deepseek/deepseek-v4-flash-latest"
        "kat-coder-air-v2.5"
        "kat-coder-pro-v2.5"
        "minimax-m3"
      ];
    };
  };

  programs.bash.enable = true;
  programs.git.enable = true;

  # Secrets: eine Datei secrets.nix, direkt beim Build importiert.
  home.sessionVariables = import ../../secrets.nix;
}
