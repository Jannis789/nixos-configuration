{ config, pkgs , ... }:

{  
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "horizon";
      vim_keys = true;
    };
  };

  programs.atuin = {
    enable = true;
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

  programs.git = {
    enable = true;
    userName  = "Jannis Rustige";
    userEmail = "jannis.rustige@gmail.com";
  };
}