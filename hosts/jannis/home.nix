{ secrets, pkgs, ... }:
{
  home.username = "jannis";
  home.homeDirectory = "/home/jannis";
  home.stateVersion = "26.11";

  imports = [
    ../../modules/home/atuin.nix
    ../../modules/home/font.nix
    ../../modules/home/gnome
    ../../modules/home/pi.nix
    ../../modules/home/ssh.nix
    ../../modules/home/starship.nix
    ../../modules/home/vscode-insiders.nix
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
  # vscode-insiders: Desktop-App UND Web-UI (jannis.nix-dev.link/vscode).
  programs.vscode-insiders = {
    enable = true;
    serveWeb = {
      enable = true;
      defaultFolder = "/home/jannis/workspace";
    };
  };
  programs.git.enable = true;

  # Cockpit liest ~/.ssh/authorized_keys (nicht den systemweiten sshd-Pfad).
  # Gleiche Public-Key-Quelle wie die NixOS-config → kein Duplikat zum Pflegen.
  home.file.".ssh/authorized_keys".text = secrets.SSH_KEYS.lannitz.public + "\n";

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
