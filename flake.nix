{
  description = "NixOS config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-grub-themes.url = "github:jeslie0/nixos-grub-themes";

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      nix-flatpak,
      darwin,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
        config = { };
      };
    in
    {
      nixosConfigurations.default = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/default/configuration.nix
          home-manager.nixosModules.default
          nix-flatpak.nixosModules.nix-flatpak
        ];
      };

      # ✅ NEU: macOS-Konfiguration
      darwinConfigurations.macbook = darwin.lib.darwinSystem {
        system = "aarch64-darwin"; # oder "x86_64-darwin" je nach Mac
        modules = [
          ./hosts/macbook/configuration.nix
          home-manager.darwinModules.home-manager
        ];
        specialArgs = { inherit inputs; };
      };

      packages.${system} = {
        catppuccin-gtk-theme = pkgs.catppuccin-gtk-theme;
      };

      overlays.default = import ./overlays/overlays.nix;
    };
}
