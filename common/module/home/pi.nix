{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.pi-coding-agent = {
    enable = true;
    settings = {
      lastChangelogVersion = "0.80.10";
      theme = "dark";
      defaultProvider = "nous";
      defaultModel = "~deepseek/deepseek-v4-flash-latest";

      packages = [
        "npm:@pi-unipi/memory"
        "npm:@dietrichgebert/ponytail"
        "npm:context-mode"
        "npm:pi-lens"
        "npm:pi-vscode-context"
        "npm:pi-mcp-adapter"
        "npm:pi-web-access"
        "npm:pi-subagents"
        "npm:bigpowers"
        "npm:pi-fabric"
        "npm:@firstpick/pi-extension-nixos-wiki-local"
        "npm:betterwright"
        "npm:@xynogen/pix-sudo"
      ];
    };
  };

  home.file.".pi/agent/models.json".text = builtins.toJSON {
    providers.nous = {
      baseUrl = "https://inference-api.nousresearch.com/v1";
      api = "openai-completions";
      apiKey = "$NOUS_API_KEY";
      models = [
        { id = "~deepseek/deepseek-v4-flash-latest"; }
        { id = "minimax-m3"; }
        { id = "stealth/ox-alpha"; }
      ];
    };
  };

  # BetterWright-Skill deklarativ im Repo — überlebt Neuaufsetzen.
  # NICHT direkt nach ~/.pi/agent/skills schreiben: home-manager linkt den
  # Store-Pfad, ein echtes Verzeichnis dort würde den Link blockieren.
  home.file.".pi/agent/skills/betterwright-driver/SKILL.md".source =
    ./pi/betterwright-driver/SKILL.md;
}
