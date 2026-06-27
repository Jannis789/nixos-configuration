{ config, pkgs, hermesPkgs, inputs, ... }:

{
  networking.hostName = "darwin";

  # hermes-agent: override anthropic dependency group for openmodell transport.
  # Optional hermesPkgs.desktop (not available on aarch64-darwin).
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
