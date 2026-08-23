{ config, pkgs, lib, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader: GRUB (EFI) — das System bootet über GRUB, nicht systemd-boot.
  # systemd-boot-Einträge wurden von v2-Builds geschrieben, aber nie gebootet.
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
  };

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

    # GNOME Shell Extensions — System-Store, damit GDM/GNOME sie in XDG_DATA_DIRS findet
    # (home.packages landet im HM-Profil, das GNOME nicht sieht)
    gnomeExtensions.blur-my-shell
    gnomeExtensions.caffeine
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.customize-clock-on-lock-screen
    gnomeExtensions.native-screenshot-ui-ocr-extended
    gnomeExtensions.user-themes
    gnomeExtensions.color-picker
    gnomeExtensions.astra-monitor
    gnomeExtensions.dash-to-dock
    gnomeExtensions.tiling-shell

    # OCR-Backend für native-screenshot-ui-ocr-extended (deu + eng)
    (tesseract5.override { enableLanguages = [ "deu" "eng" ]; })
  ];

  # Steam + neuester Proton-GE (extraCompatPackages liefert die GE-Versionen)
  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

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

  system.stateVersion = "26.11";
}
