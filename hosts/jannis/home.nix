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
    ../../common/module/home/starship.nix
    ../../common/module/vscode-insiders.nix
  ];

  programs.bash.enable = true;

  # Shell-History: atuin (Config in common/module/home/atuin.nix)
  # sessionVariables (NOUS_API_KEY aus secrets.nix) landen nur in hm-session-vars.sh,
  # das nur von Login-Shells gesourct wird. Auch in interaktive Shells bringen:
  # initExtra = ~/.bashrc (interaktive Shells); hm-session-vars wird sonst nur
  # von Login-Shells (.profile) gesourct.
  programs.bash.initExtra = ''
    . "$HOME/.local/state/home-manager/gcroots/current-home/home-path/etc/profile.d/hm-session-vars.sh"
  '';
  programs.vscode-insiders.enable = true;
  programs.git.enable = true;

  # Terminal + Pakete
  home.packages = with pkgs; [
    ghostty
  ];

  # Secrets: eine Datei secrets.nix, direkt beim Build importiert.
  home.sessionVariables = secrets;
}
