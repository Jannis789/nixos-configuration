{ config, pkgs, hermesPkgs, inputs, ... }:

{
  networking.hostName = "darwin";

  # hermes-agent CLI: `anthropic` dependency group aktiviert die SDK-Deps
  # fuer die anthropic_messages Transport-Schicht (gebraucht vom custom
  # `openmodell` Provider, siehe modules/hermes-config.nix).
  # `hermesPkgs.desktop` ist ein Linux-Electron-Wrapper mit .desktop-Files;
  # auf aarch64-darwin kann der Flake-Output fehlen — nur einbinden wenn da.
  environment.systemPackages = with pkgs; [
    (hermesPkgs.default.override { extraDependencyGroups = [ "anthropic" ]; })
  ] ++ pkgs.lib.optional (hermesPkgs ? desktop) hermesPkgs.desktop;

  system.primaryUser = config.system.userName;
  system.defaults = {
    dock.autohide = true;
    finder.ShowPathbar = true;
    finder.ShowStatusBar = true;
  };

  time.timeZone = "Europe/Berlin";

  services.openssh = {
    enable = true;
    extraConfig = ''
      PermitRootLogin no
      PasswordAuthentication no
    '';
  };

  # ── Homebrew (nix-managed) ────────────────────────────────────
  nix-homebrew = {
    enable = true;
    user = config.system.userName;
    autoMigrate = true;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
    mutableTaps = false;
  };
  homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
  homebrew.brews = [ "ant" ];
}
