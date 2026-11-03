{ secrets, pkgs, betterfox, ... }:
{
  home.username = "jannis";
  home.homeDirectory = "/home/jannis";
  home.stateVersion = "26.11";

  imports = [
    ../../modules/home/atuin.nix
    ../../modules/home/font.nix
    ../../modules/home/theme.nix
    ../../modules/home/gnome
    ../../modules/home/goose.nix
    ../../modules/home/toad.nix
    ../../modules/home/ssh.nix
    ../../modules/home/starship.nix
    ../../modules/home/terminal-browser.nix
    ../../modules/home/vscode-insiders.nix
  ];

  programs.bash.enable = true;

  # Browser mit vollem Erweiterungs-Support (uBlock etc.) + Stylix-Targeting.
  # Profil "default" wird deklarativ erzeugt; Stylix schreibt userChrome.css rein.
  programs.firefox = {
    enable = true;
    profiles."default" = {
      # Betterfox-Privacy-Overlay deklarativ: user.js ins Profil mergen.
      # extraConfig laeuft nach den HM-settings -> Betterfox kann sie kippen,
      # deshalb danach die Stylix-/Theme-Prefs explizit nachziehen.
      extraConfig = builtins.readFile "${betterfox}/user.js" + ''

        /* Stylix-/Theme-Prefs nachziehen (Firefox-GNOME-Theme + base16) */
        user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
        user_pref("svg.context-properties.content.enabled", true);
      '';
    };

    # nixpkgs-firefox erzwingt MOZ_LEGACY_PROFILES=1 -> liest ~/.mozilla/firefox
    # (nicht die XDG-GO). configPath einnorden, damit das Stylix-Theme dort landet.
    configPath = ".mozilla/firefox";
  };

  programs.bash.initExtra = ''
    # Guard ist ein vererbtes Once-Flag: Ohne unset sourct hm-session-vars.sh bei
    # jedem spaeteren Source sofort return und neu hinzugekommene Keys (z.B.
    # OPENCODE_API_KEY) werden nie geladen. unset macht es deterministisch.
    unset __HM_SESS_VARS_SOURCED
    . "$HOME/.local/state/home-manager/gcroots/current-home/home-path/etc/profile.d/hm-session-vars.sh"
    fastfetch
  '';
  # vscode-insiders: Desktop-App UND Web-UI (jannis.nix-dev.link/vscode).
  programs.vscode-insiders = {
    enable = true;
    serveWeb = {
      enable = true;
      defaultFolder = "/home/jannis/workspace";
    };
  };
  # terminal-browser: Browser im Terminal. Paket + Agent-Skill-Links (~/.agents,
  # ~/.claude, ~/.codex, ~/.gemini) deklarativ statt per `terminal-browser setup`.
  # AppArmor-Profil entfällt: die Derivation macht chrome-sandbox setuid.
  programs.terminal-browser.enable = true;

  programs.git.enable = true;

  # Cockpit liest ~/.ssh/authorized_keys (nicht den systemweiten sshd-Pfad).
  # Gleiche Public-Key-Quelle wie die NixOS-config → kein Duplikat zum Pflegen.
  home.file.".ssh/authorized_keys".text = secrets.SSH_KEYS.lannitz.public + "\n";

  home.packages = with pkgs; [
    ghostty
    fastfetch
  ];

  # nur Modell-Keys in die Session — CF_DNS_API_TOKEN braucht nur das Root-Activation-Skript
  # (SSH_KEYS ist ein Attrset, Keys liegen in home.file)
  home.sessionVariables = {
    ZAI_API_KEY = secrets.ZAI_API_KEY;
    # Der native goose-ZAI-Coding-Plan-Provider liest diesen Key (nicht ZAI_API_KEY).
    ZAI_CODING_PLAN_API_KEY = secrets.ZAI_API_KEY;
    OPENCODE_API_KEY = secrets.OPENCODE_API_KEY;
    # custom_nous-Provider (goose) liest diesen Key aus der Env.
    NOUS_API_KEY = secrets.NOUS_API_KEY;
  };
}
