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

  home.stateVersion = "25.11";
  home.enableNixpkgsReleaseCheck = false;

  home.packages = [
    pkgs.blesh
    pkgs.atuin
    pkgs.nix-bash-completions
    pkgs.zoxide
    pkgs.starship
    pkgs.andromeda-gtk-theme
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.starship.enable = true;

  programs.bash.enable = true;

  programs.bash.bashrcExtra = builtins.readFile ../../.dotfiles/.bashrc;

  home.file = {
    ".config" = {
      source = ../../.dotfiles-laptop/.config;
      recursive = true;
    };
    ".local" = {
      # BugFix: .dotfiles-laptop/.local/share/locale/de/LC_MESSAGES/nautilus-open-any-terminal.mo
      source = ../../.dotfiles-laptop/.local;
      recursive = true;
    };
    ".ssh" = {
      source = ../../.dotfiles/.ssh;
      recursive = true;
    };
    ".themes" = {
      source = config.lib.file.mkOutOfStoreSymlink "${pkgs.magnetic-catppuccin-gtk}/share/themes";
    };
  };

  xdg.configFile = {
    "gtk-4.0/assets".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/assets";
    "gtk-4.0/gtk.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk.css";
    "gtk-4.0/gtk-dark.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk-dark.css";
  };
}
