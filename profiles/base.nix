{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.system;
in
{
  options.system = {
    userName = lib.mkOption {
      type = lib.types.str;
      default = "jannis";
    };
    homeStateVersion = lib.mkOption {
      type = lib.types.str;
      default = "26.05";
    };
  };

  config = {
    system.stateVersion = "26.05";

    nix.extraOptions = ''
      experimental-features = nix-command flakes
    '';

    networking.networkmanager = {
      enable = true;
      plugins = [ pkgs.networkmanager-openvpn ];
    };

    users.users.${cfg.userName} = {
      isNormalUser = true;
      shell = pkgs.bash;
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
    };

    services.gnome.gnome-keyring.enable = true;
  };
}
