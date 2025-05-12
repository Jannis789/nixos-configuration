# hosts/macbook/home.nix

{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.username = "jrustige";
  home.homeDirectory = "/home/jrustige";
  nixpkgs.config.allowUnfree = true;

  home.stateVersion = "25.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
