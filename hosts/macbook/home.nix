# hosts/macbook/home.nix

{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.username = "jrustige";
  home.homeDirectory = "/Users/jrustige";
  nixpkgs.config.allowUnfree = true;

  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  home.file = {
    ".config" = {
      source = ../../.dotfiles-darwin/.config;
      recursive = true;
    };
    ".bashrc" = {
      source = ../../.dotfiles-darwin/.bashrc;
    };
  };
}
