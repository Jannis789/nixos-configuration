{
  config,
  lib,
  pkgs,
  goosePkg,
  ...
}:
{
 
 
 
 
  options.gooseAgent = {
    defaultProvider = lib.mkOption {
      type = lib.types.str;
      default = "custom_zai";
    };
    defaultModel = lib.mkOption {
      type = lib.types.str;
      default = "glm-5.3";
    };
  };

  config = {
   
   
   
    home.packages = [ goosePkg ];

   
   
   
   
   
    home.sessionVariables = {
      GOOSE_PROVIDER = config.gooseAgent.defaultProvider;
      GOOSE_MODEL = config.gooseAgent.defaultModel;
    };

   
   
      
   
   
    home.file.".config/goose/custom_providers/custom_zai.json" = {
      source = ../assets/goose/custom_zai.json;
      force = true;
    };
   
   
   
    home.file.".config/goose/custom_providers/custom_opencode.json" = {
      source = ../assets/goose/custom_opencode.json;
      force = true;
    };

    home.file.".config/goose/custom_providers/custom_nous.json" = {
      source = ../assets/goose/custom_nous.json;
      force = true;
    };
  };
}
