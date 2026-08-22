{
  description = "NixOS configuration v2 — ein Host, minimal";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }: {
    nixosConfigurations.jannis = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/jannis/configuration.nix
        home-manager.nixosModules.home-manager
        {
          # Overlay: custom Pakete (helium)
          nixpkgs.overlays = [
            (final: prev: {
              helium = final.callPackage ./common/module/custom/helium.nix { };
            })
          ];

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.jannis = import ./hosts/jannis/home.nix;
          };
        }
      ];
    };
  };
}
