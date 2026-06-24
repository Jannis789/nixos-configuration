{
  inputs,
  nixpkgs,
  home-manager,
  nix-darwin,
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
      # hermes-packages direkt via specialArgs verfügbar machen
      hermesPkgs = inputs.hermes-agent.packages.${system};
    };

    modules = [
      ../profiles/darwin.nix
      ../hosts/${hostName}/default.nix
      ../hosts/${hostName}/overrides.nix

      # hermes-agent und hermes-desktop via environment.systemPackages
      # werden direkt in hosts/darwin/default.nix referenziert, wo
      # inputs.hermes-agent.packages.${system} via specialArgs verfügbar ist

      inputs.home-manager.darwinModules.home-manager

      {
        system.userName = userName;
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "before-nix";
        home-manager.extraSpecialArgs = {
          inherit inputs;
          # Auch für home-manager: hermesPkgs + secrets explizit
          hermesPkgs = inputs.hermes-agent.packages.${system};
        };
        home-manager.users.${userName} = import ../home/darwin.nix;
      }
    ];
  };
}
