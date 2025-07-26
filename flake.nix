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

    nixvim.url = "github:Jannis789/nixvim?ref=main";
  };

  outputs = inputs@{
    self,
    nixpkgs,
    home-manager,
    nix-flatpak,
    darwin,
    nixvim,
    ...
  }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ self.overlays.laptop ];
      config = { };
    };
  in
  {
    # NixOS-Konfiguration
    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/default/configuration.nix
        home-manager.nixosModules.default
        nix-flatpak.nixosModules.nix-flatpak
      ];
    };

    # NixOS-Konfiguration (laptop)
    nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/laptop/configuration.nix
        home-manager.nixosModules.default
        nix-flatpak.nixosModules.nix-flatpak
      ];
    };

    # macOS-Konfiguration
    darwinConfigurations.macbook = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ./hosts/macbook/configuration.nix
        home-manager.darwinModules.home-manager
      ];
      specialArgs = { inherit inputs; };
    };

    packages.${system} = {
      andromeda-gtk-theme = pkgs.andromeda-gtk-theme;
    };

    overlays.default = import ./overlays/extra-pkgs.nix;

  };
}
