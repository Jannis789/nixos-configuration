{ config, lib, pkgs, ... }:

{
  options.system = {
    userName = lib.mkOption {
      type = lib.types.str;
      default = "jrustige";
    };
    homeStateVersion = lib.mkOption {
      type = lib.types.str;
      default = "25.05";
    };
  };

  config = {
    nix.extraOptions = ''
      experimental-features = nix-command flakes
    '';

    system.stateVersion = 7;

    users.users.${config.system.userName} = {
      home = "/Users/${config.system.userName}";
    };
  };
}
