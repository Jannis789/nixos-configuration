{ pkgs, lib, ... }:
{
  programs.atuin = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;

    flags = [ "--disable-up-arrow" ];

    settings = {
      auto_sync = false;

      theme = {
        name = "catppuccin-mocha-mauve";
      };
    };

    forceOverwriteSettings = true;

    themes = {
      "catppuccin-mocha-mauve" = {
        theme.name = "Catppuccin Mocha Mauve";
        colors = {
          AlertInfo = "#a6e3a1";
          AlertWarn = "#fab387";
          AlertError = "#f38ba8";
          Annotation = "#cba6f7";
          Base = "#cdd6f4";
          Guidance = "#9399b2";
          Important = "#f38ba8";
          Title = "#cba6f7";
        };
      };
    };
  };
}
