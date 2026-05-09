{
  config,
  lib,
  pkgs,
  ...
}:

let
  grubProfiles = {
    default = {
      enable = true;
      efiSupport = true;
      useOSProber = config.grub.useOSProber;
      device = "nodev";
      theme = if config.grub.theme != null then config.grub.theme else pkgs.catppuccin-grub;
      splashImage = if config.grub.theme != null then null else "${pkgs.catppuccin-grub}/background.png";
    };
  };
  grubProfileName = config.grub.profile;
in
{
  options.grub = {
    profile = lib.mkOption {
      type = lib.types.str;
      default = "default";
    };
    useOSProber = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    theme = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
    };
  };

  config.boot.loader = {
    grub = grubProfiles.${grubProfileName};
    systemd-boot.enable = false;
    efi.canTouchEfiVariables = true;
  };
}
