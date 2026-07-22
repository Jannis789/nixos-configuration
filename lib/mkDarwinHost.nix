{
  inputs,
  nixpkgs,
  home-manager,
  nix-darwin,
  nix-homebrew,
}:

hostName: cfg:

let
  system = cfg.system;
  userName = cfg.userName;

  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [ ((import ../overlays.nix) { inherit inputs; }) ];
  };
in
{
  darwinConfigurations.${hostName} = nix-darwin.lib.darwinSystem {
    inherit system pkgs;

    specialArgs = {
      inherit inputs hostName;
      hermesPkgs = inputs.hermes-agent.packages.${system};
    };

    modules = [
      nix-homebrew.darwinModules.nix-homebrew
      ../profiles/darwin.nix
      ../hosts/${hostName}/default.nix
      ../hosts/${hostName}/overrides.nix
      inputs.home-manager.darwinModules.home-manager

      {
        system.userName = userName;
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "before-nix";
        home-manager.extraSpecialArgs = {
          inherit inputs;
          hermesPkgs = inputs.hermes-agent.packages.${system};
        };
        home-manager.users.${userName} = import ../home/darwin/default.nix;
      }
    ];
  };
}
