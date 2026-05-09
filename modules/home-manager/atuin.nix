{ config, lib, ... }:

let
  profiles = {
    default = {
      enableBashIntegration = true;
      settings = {
        auto_sync = true;
        sync_frequency = "5m";
        sync_address = "https://api.atuin.sh";
        search_mode = "fuzzy";
        theme = {
          name = "catppuccin-mocha-blue";
        };
      };
      flags = [ "--disable-up-arrow" ];
    };
  };
  profileName = config.atuin.profile;
in
{
  options.atuin.profile = lib.mkOption {
    type = lib.types.str;
    default = "default";
  };

  config.programs.atuin = profiles.${profileName} // {
    enable = true;
  };
}
