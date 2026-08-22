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
  };
}
