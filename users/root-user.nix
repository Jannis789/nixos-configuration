{ lib, config, pkgs, ... }:

let 
  cfg = config.root-user; 
in { 
  options.root-user = { 
    enable = lib.mkEnableOption "Enable the custom root user module"; 
    
    userName = lib.mkOption { 
      type = lib.types.str;
      default = "root"; 
      description = ''The username for the main user'';
    };

    userPassword = lib.mkOption {
      type = lib.types.str;
      default = "root";  # In der Praxis solltest du hier etwas Sicheres setzen oder leer lassen
      description = ''The initial password for the user'';
    };
  };

  config = lib.mkIf cfg.enable { 
    users.users.${cfg.userName} = { 
      isNormalUser = true; 
      initialPassword = cfg.userPassword;
      description = "Main user configured by root-user module"; 
      extraGroups = [ "networkmanager" "wheel" ];
      shell = pkgs.bash;
      packages = with pkgs; [];
    };
  };
}

