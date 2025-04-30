# hosts/default/home.nix
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # User Configuration
  home.username = "jannis";
  home.homeDirectory = "/home/jannis";

  nixpkgs.config.allowUnfree = true;

  imports = [
    ../../modules/home-manager/development/cli.nix
    ../../modules/home-manager/development/vscode.nix
    ../../modules/home-manager/gnome/dconf.nix
    ../../modules/home-manager/gnome/extensions.nix
    ../../modules/home-manager/gnome/gtk.nix
    ../../modules/home-manager/web.nix
  ];

  home.stateVersion = "25.05";

  nixpkgs.overlays = [ (import ../../overlays/overlays.nix) ];

  home.packages = [
    pkgs.catppuccin-gtk-theme
    pkgs.blesh
    pkgs.atuin
    pkgs.nix-bash-completions
    pkgs.zoxide
    pkgs.starship
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.starship.enable = true;

  programs.bash.enable = true;

  programs.bash.bashrcExtra = builtins.readFile ../../.dotfiles/.bashrc;

  home.file = {
    ".config" = {
      source = ../../.dotfiles/.config;
      recursive = true;
    };
    ".local" = {
      # BugFix: .dotfiles/.local/share/locale/de/LC_MESSAGES/nautilus-open-any-terminal.mo
      source = ../../.dotfiles/.local;
      recursive = true;
    };
    ".ssh" = {
      source = ../../.dotfiles/.ssh;
      recursive = true;
    };
  };
}
