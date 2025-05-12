# hosts/macbook/configuration.nix

{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    ../../users/darwin-user.nix
    ../../pkgs/cli-darwin.nix
    inputs.home-manager.darwinModules.home-manager
  ];

  darwin-user.enable = true;
  darwin-user.userName = "jrustige";
  darwin-user.userPassword = "prodata";

  home-manager = {
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };
    users = {
      "jrustige" = import ./home.nix;
    };
  };

  programs.bash.blesh.enable = true;

  system.stateVersion = 6;
}
