{ pkgs, lib, ... }:
{
  programs.atuin = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;

    # ↑ deaktivieren — History-Suche nur noch über Strg+R.
    # ponytail: --disable-up-arrow per flag, wie vom Modul vorgesehen.
    flags = [ "--disable-up-arrow" ];

    # Kein Sync-Server — lokal, ohne Verbindungsversuche.
    settings = {
      auto_sync = false;
    };

    # atuin schreibt seine Default-config.toml nach jedem Befehl neu —
    # ohne force blockiert HM die Aktivierung (clobber-Schutz).
    forceOverwriteSettings = true;

    # Catppuccin Mocha (Mauve-Akzent) — Farben aus deiner Vorgabe.
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
