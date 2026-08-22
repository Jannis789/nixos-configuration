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
  ];

  # sshd — standard, nur LAN (jannis kann selbst schalten)
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;

  # Nix: flakes + substituters
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [ "https://cache.nixos.org" ];
  };

  # Secrets (lazy + Submodule): /run/secrets zur Laufzeit aus dem privaten
  # secrets-Submodule deployen (nix eval + jq, dotenv-Format). Kein
  # Store-Leak: Werte werden nie in die Config interpoliert, und kein
  # pathExists beim Eval (Submodule-Pfad ist in der Flake-Sandbox nicht
  # sichtbar → Script würde sonst still weggelassen).
  system.activationScripts.secrets = ''
    mkdir -p /run/secrets
    chmod 0700 /run/secrets
    for f in api-keys web-control-token darwin-zsh; do
      if [ -f "/home/jannis/workspace/nixos-configuration-v2/secrets/$f.nix" ]; then
        ${pkgs.nix}/bin/nix eval --impure --json --expr "import /home/jannis/workspace/nixos-configuration-v2/secrets/$f.nix" \
          | ${pkgs.jq}/bin/jq -r 'to_entries[] | "\(.key)=\(.value)"' \
          > /run/secrets/$f
      fi
    done
    chmod 0400 /run/secrets/* 2>/dev/null || true
  '';

  system.stateVersion = "26.05";
}
