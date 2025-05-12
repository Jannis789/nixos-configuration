# hosts/macbook/home.nix

{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.username = "jannis";
  home.homeDirectory = "/home/jannis";
  nixpkgs.config.allowUnfree = true;

  home.stateVersion = 6;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
