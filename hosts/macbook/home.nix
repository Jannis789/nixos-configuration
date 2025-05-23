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

  imports = [
    ../../modules/home-manager/development/cli-darwin.nix
  ];

  home.stateVersion = "25.11";

  home.enableNixpkgsReleaseCheck = false;

  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    bashrcExtra = builtins.readFile ../../.dotfiles-darwin/.bashrc;
  };

  home.file = {
    ".config" = {
      source = ../../.dotfiles-darwin/.config;
      recursive = true;
    };
  };
}
