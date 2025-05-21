{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.darwin-user;
in
{
  options.darwin-user = {
    enable = lib.mkEnableOption "Enable the custom root user module";

    userName = lib.mkOption {
      type = lib.types.str;
      default = "root";
      description = ''The username for the main user'';
    };

    userPassword = lib.mkOption {
      type = lib.types.str;
      default = "root";
      description = ''The initial password for the user'';
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.userName} = {
      description = "Main user configured by darwin-user module";
      shell = pkgs.bash;
      packages = with pkgs; [ ];
      home = "/Users/jrustige";
    };
  };
}
