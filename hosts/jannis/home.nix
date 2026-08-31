{ secrets, pkgs, ... }:
{
  home.username = "jannis";
  home.homeDirectory = "/home/jannis";
  home.stateVersion = "26.11";

  imports = [
    ../../common/module/home/atuin.nix
    ../../common/module/home/font.nix
    ../../common/module/home/gnome
    ../../common/module/home/pi.nix
    ../../common/module/home/ssh.nix
    ../../common/module/home/starship.nix
    ../../common/module/vscode-insiders.nix
  ];

  programs.bash.enable = true;

  programs.bash.initExtra = ''
    # Guard ist ein vererbtes Once-Flag: Ohne unset sourct hm-session-vars.sh bei
    # jedem spaeteren Source sofort return und neu hinzugekommene Keys (z.B.
    # OPENCODE_API_KEY) werden nie geladen. unset macht es deterministisch.
    unset __HM_SESS_VARS_SOURCED
    . "$HOME/.local/state/home-manager/gcroots/current-home/home-path/etc/profile.d/hm-session-vars.sh"
    fastfetch
  '';
  programs.vscode-insiders.enable = true;
  programs.git.enable = true;

  home.packages = with pkgs; [
    ghostty
    rewaita
    fastfetch
  ];

  # nur Modell-Keys in die Session — CF_DNS_API_TOKEN braucht nur das Root-Activation-Skript
  # (SSH_KEYS ist ein Attrset, Keys liegen in home.file)
  home.sessionVariables = {
    NOUS_API_KEY = secrets.NOUS_API_KEY;
    ZAI_API_KEY = secrets.ZAI_API_KEY;
    OPENCODE_API_KEY = secrets.OPENCODE_API_KEY;
  };
}
