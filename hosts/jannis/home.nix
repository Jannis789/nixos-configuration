{ pkgs, ... }:
{
  home.username = "jannis";
  home.homeDirectory = "/home/jannis";
  home.stateVersion = "26.05";

  imports = [
    ../../common/module/home/font.nix
    ../../common/module/home/gnome
    ../../common/module/home/pi.nix
    ../../common/module/home/starship.nix
    ../../common/module/vscode-insiders.nix
  ];

  programs.bash.enable = true;
  programs.vscode-insiders.enable = true;
  programs.git.enable = true;

  # Terminal + Pakete
  home.packages = with pkgs; [
    ghostty
  ];

  # Secrets: eine Datei secrets.nix, direkt beim Build importiert.
  home.sessionVariables = import ../../secrets.nix;
}
