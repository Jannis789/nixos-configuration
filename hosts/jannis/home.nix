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
    if [ -r /run/agenix/api-keys-env ]; then . /run/agenix/api-keys-env; fi
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

  programs.git = {
    enable = true;
    userName = "jannis";
    userEmail = "jannis@nix-dev.link";
  };

  home.file.".ssh/authorized_keys".text = secrets.SSH_KEYS.lannitz.public + "\n";

  home.packages = with pkgs; [
    ghostty
    fastfetch
  ];

  # API-Keys kommen aus dem age-Secret "api-keys-env" und werden in
  # programs.bash.initExtra aus /run/agenix/api-keys-env gesourced.
}
