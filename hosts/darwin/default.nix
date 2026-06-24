{ config, pkgs, hermesPkgs, ... }:

{
  networking.hostName = "darwin";

  # ── System-wide Packages ──────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    (hermesPkgs.default.override { extraDependencyGroups = [ "anthropic" ]; })
    hermesPkgs.desktop     # hermes-desktop
  ];

  # ── macOS Defaults (nur anwendbar wenn primaryUser gesetzt) ────────────
  system.primaryUser = config.system.userName;
  system.defaults = {
    dock.autohide = true;
    finder.ShowPathbar = true;
    finder.ShowStatusBar = true;
  };

  # ── Locale & Time ─────────────────────────────────────────────────────────
  time.timeZone = "Europe/Berlin";

  # ── SSH ──────────────────────────────────────────────────────────────────
  services.openssh = {
    enable = true;
    extraConfig = ''
      PermitRootLogin no
      PasswordAuthentication no
    '';
  };
}
