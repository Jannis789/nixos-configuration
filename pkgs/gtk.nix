{ config, pkgs, ... }:

{
  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  environment.gnome.excludePackages = with pkgs; [
    gnome-music
    gnome-tour
    gnome-logs
    geary
    totem
  ];
  
  environment.systemPackages = with pkgs; [
    fragments
    protonplus
    steam
    lutris
    gnome-tweaks
    dconf-editor
    flat-remix-icon-theme
    graphite-cursors
  ];
}
