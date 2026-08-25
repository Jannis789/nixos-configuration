{ lib, secrets, pkgs, ... }:
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

  # nur Strings exportieren — SSH_KEYS ist ein Attrset (Keys liegen in home.file)
  home.sessionVariables = lib.filterAttrs (_: v: builtins.isString v) secrets;
}
