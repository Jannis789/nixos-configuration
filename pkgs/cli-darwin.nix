{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    blesh
    btop
    fastfetch
    wget
    git
    starship
    atuin
    zoxide
    nix-bash-completions
    nixfmt-rfc-style
    git-credential-manager
    openssh
    wl-clipboard
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.symbols-only
  ];

  programs.bash = {
    completion.enable = true;
  };

}
