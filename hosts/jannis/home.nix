{
  secrets,
  pkgs,
  betterfox,
  ...
}:
{
  home.username = "jannis";
  home.homeDirectory = "/home/jannis";
  home.stateVersion = "26.11";

  imports = [
    ../../modules/atuin.nix
    ../../modules/font.nix
    ../../modules/theme.nix
    ../../modules/gnome
    ../../modules/goose.nix
    ../../modules/ssh.nix
    ../../modules/starship.nix
    ../../modules/terminal-browser.nix
    ../../modules/vscode-insiders.nix
    ../../modules/workspace.nix
  ];

  programs.bash.enable = true;

  programs.firefox = {
    enable = true;
    profiles."default" = {
      extraConfig = builtins.readFile "${betterfox}/user.js" + ''

        /* Stylix-/Theme-Prefs nachziehen (Firefox-GNOME-Theme + base16) */
        user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
        user_pref("svg.context-properties.content.enabled", true);
      '';
    };
    configPath = ".mozilla/firefox";
  };

  programs.bash.initExtra = ''
    unset __HM_SESS_VARS_SOURCED
    . "$HOME/.local/state/home-manager/gcroots/current-home/home-path/etc/profile.d/hm-session-vars.sh"
    fastfetch
  '';

  programs.vscode-insiders = {
    enable = true;
    serveWeb = {
      enable = true;
      defaultFolder = "/home/jannis/workspace";
    };
  };

  programs.terminal-browser.enable = true;

  programs.git.enable = true;

  home.file.".ssh/authorized_keys".text = secrets.SSH_KEYS.lannitz.public + "\n";

  home.packages = with pkgs; [
    ghostty
    fastfetch
  ];

  home.sessionVariables = {
    ZAI_API_KEY = secrets.ZAI_API_KEY;
    ZAI_CODING_PLAN_API_KEY = secrets.ZAI_API_KEY;
    OPENCODE_API_KEY = secrets.OPENCODE_API_KEY;
    NOUS_API_KEY = secrets.NOUS_API_KEY;
  };
}
