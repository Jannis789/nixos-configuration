{
  description = "NixOS configuration v2 — Hosts über mkHost";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nix-darwin,
      nix-homebrew,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      secrets = import ./secrets.nix;

      overlays = import ./common/overlays.nix { };

      mkHost =
        {
          kind,
          system,
          configuration,
          username,
          home,
          hostOverlays ? [ ],
          extraModules ? [ ],
        }:
        let
          isNixos = kind == "nixos";
          hmModule =
            if isNixos then home-manager.nixosModules.home-manager else home-manager.darwinModules.home-manager;
        in
        (if isNixos then nixpkgs.lib.nixosSystem else nix-darwin.lib.darwinSystem) {
          inherit system;

          specialArgs = { inherit inputs; };

          modules = [
            configuration
            hmModule
          ]
          ++ extraModules
          ++ lib.optionals (!isNixos) [ nix-homebrew.darwinModules.nix-homebrew ]
          ++ [
            {
              nixpkgs.config.allowUnfree = true;
              nixpkgs.overlays = [
                overlays."vscode-insiders"
                overlays.hanabi
              ]
              ++ hostOverlays;

              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;

                extraSpecialArgs = { inherit secrets; };

                users.${username} = import home;
              };
            }
          ];
        };
    in
    {
      nixosConfigurations.jannis = mkHost {
        kind = "nixos";
        system = "x86_64-linux";
        configuration = ./hosts/jannis/configuration.nix;
        username = "jannis";
        home = ./hosts/jannis/home.nix;
        hostOverlays = [
          overlays.helium
          overlays.rewaita
          overlays.epiphany-webext
        ];
      };

      nixosConfigurations.cachyos-latest = mkHost {
        kind = "nixos";
        system = "x86_64-linux";
        configuration = ./hosts/jannis/configuration.nix;
        username = "jannis";
        home = ./hosts/jannis/home.nix;
        hostOverlays = [
          overlays.helium
          overlays.rewaita
          overlays.epiphany-webext
        ];
        extraModules = [
          {
            boot.kernelPackages =
              inputs.cachyos-kernel.legacyPackages.x86_64-linux.linuxPackages-cachyos-latest;
          }
        ];
      };

      darwinConfigurations.darwin = mkHost {
        kind = "darwin";
        system = "aarch64-darwin";
        configuration = ./hosts/darwin/configuration.nix;
        username = "jrustige";
        home = ./hosts/darwin/home.nix;
      };
    };
}
