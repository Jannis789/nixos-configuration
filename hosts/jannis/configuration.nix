{ config, pkgs, lib, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Hostname + Netzwerk
  networking.hostName = "jannis";
  networking.networkmanager.enable = true;

  # Locale / Zeit (deutsch)
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";
  console.keyMap = "de";

  # Benutzer: jannis (wheel + networkmanager)
  users.users.jannis = {
    isNormalUser = true;
    initialPassword = "changeme";
    extraGroups = [ "wheel" "networkmanager" ];
  };
  # sudo ohne Passwort (Jannis' Workflow: rebuilds im Terminal)
  security.sudo.wheelNeedsPassword = false;

  # GNOME Desktop — Wayland only (GNOME 50 hat kein X11 mehr)
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Basispakete
  environment.systemPackages = with pkgs; [
    git
    curl
    vim
    helium
  ];

  # sshd — standard, nur LAN (jannis kann selbst schalten)
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;

  # Nix: flakes + substituters
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [ "https://cache.nixos.org" ];
  };

  # Unfree (vscode etc.)
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "26.05";
}
