{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    btop
    fastfetch
    vim 
    wget
    git
    starship
  ];
}
