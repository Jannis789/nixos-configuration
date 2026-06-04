{
  inputs,
  nixpkgs,
  home-manager,
}:

hostName: cfg:

let
  system = cfg.system;
  userName = cfg.userName;

  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [ (import ../overlays.nix) ];
  };
in
{
  nixosConfigurations.${hostName} = nixpkgs.lib.nixosSystem {
    inherit system pkgs;

    specialArgs = {
      inherit inputs hostName;
    };

    modules = [
      ../profiles/base.nix
      ../profiles/desktop.nix
      ../hosts/${hostName}/default.nix
      ../hosts/${hostName}/hardware-configuration.nix
      ../hosts/${hostName}/overrides.nix

      inputs.home-manager.nixosModules.home-manager
      inputs.nix-flatpak.nixosModules.nix-flatpak
      inputs.hermes-agent.nixosModules.default

      {
        nixpkgs.overlays = [ inputs.cachyos-kernel.overlays.default ];
      }

      {
        system.userName = userName;
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit inputs; };
        home-manager.users.${userName} = import ../home/common.nix;
      }
    ];
  };
}
