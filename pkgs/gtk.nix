{ config, pkgs, ... }:

{
  # Enable the GNOME Desktop Environment.
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;

  environment.gnome.excludePackages = with pkgs; [
    gnome-music
    gnome-tour
    gnome-logs
    geary
    totem
    epiphany
    firefox
    gnome-console
    gnome-system-monitor
  ];

  environment.systemPackages = with pkgs; [
    fragments
    magnetic-catppuccin-gtk
    gnome-tweaks
    dconf-editor
    colloid-icon-theme
    graphite-cursors
    nautilus-open-any-terminal
    blackbox-terminal
    mission-center
  ];
}
