{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    btop
    fastfetch
    vim 
    wget
    git
    starship
    atuin
    zoxide
    nix-bash-completions
    blesh
    gettext
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
