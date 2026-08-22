{
  description = "NixOS configuration v2 — ein Host, minimal";

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
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, nix-homebrew, ... }@inputs: {
    # ===== Linux Host: jannis =====
    nixosConfigurations.jannis = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/jannis/configuration.nix
        home-manager.nixosModules.home-manager
        {
          # Overlay: custom Pakete (helium, vscode-insiders)
          nixpkgs.overlays = [
            (final: prev: {
              helium = final.callPackage ./common/module/custom/helium.nix { };

              # Insiders Build laut Doku (wiki.nixos.org/Visual_Studio_Code#Insiders_Build)
              vscode-insiders = (prev.vscode.override { isInsiders = true; }).overrideAttrs (oldAttrs: rec {
                src = builtins.fetchTarball {
                  url = "https://code.visualstudio.com/sha/download?build=insider&os=linux-x64";
                  sha256 = "1vakxryvpi7v8065r93pxr9lyx1gpw0389bjpsidw99snjr9r842";
                };
                version = "latest";
                buildInputs = oldAttrs.buildInputs ++ [ prev.krb5 prev.libsoup_3 prev.webkitgtk_4_1 ];
              });
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

    # ===== macOS Host: darwin (nix-darwin) =====
    darwinConfigurations.darwin = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/darwin/configuration.nix
        nix-homebrew.darwinModules.nix-homebrew
        home-manager.darwinModules.home-manager
        {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.overlays = [
            (final: prev: {
              # Insiders auf macOS — anderer Download-URL als Linux
              vscode-insiders = (prev.vscode.override { isInsiders = true; }).overrideAttrs (oldAttrs: rec {
                src = prev.fetchurl {
                  url = "https://update.code.visualstudio.com/latest/darwin-arm64/insider";
                  sha256 = "sha256-VfzjdQoRFBOcDuJaK+TbjVPdGFghiDtUb7qiW7ltZnU=";
                };
                sourceRoot = ".";
                version = "latest";
              });
            })
          ];

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.jrustige = import ./hosts/darwin/home.nix;
          };
        }
      ];
    };
  };
}
