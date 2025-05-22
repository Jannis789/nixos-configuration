{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    btop
    fastfetch
    wget
    git
    starship
    atuin
    zoxide
    nix-bash-completions
    blesh
    nixfmt-rfc-style
    git-credential-manager
    openssh
    wl-clipboard
    unzip
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.symbols-only
  ];

  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "blackbox";
  };
}
