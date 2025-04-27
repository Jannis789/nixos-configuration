# home.nix
{ config, lib, pkgs, ... }:

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
  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
    pkgs.catppuccin-gtk-theme
    pkgs.blesh
    pkgs.atuin
    pkgs.nix-bash-completions
    pkgs.zoxide
    pkgs.starship
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/jannis/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.librewolf.enable = true;

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
  };
}
