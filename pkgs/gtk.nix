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
