{
  description = "NixOS Multi-Host Configuration";

  inputs = {
    self = {
      url = "git+file:./?submodules=1";
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim.url = "github:Jannis789/nixvim?ref=main";

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    hermes-agent.url = "github:NousResearch/hermes-agent";

    cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      mkHost = import ./lib/mkHost.nix { inherit inputs nixpkgs home-manager; };

      hosts = {
        jannis = {
          system = "x86_64-linux";
          userName = "jannis";
        };
        laptop = {
          system = "x86_64-linux";
          userName = "jannis";
        };
      };
    in
    nixpkgs.lib.foldl' nixpkgs.lib.recursiveUpdate { } (
      map (hostName: mkHost hostName hosts.${hostName}) (builtins.attrNames hosts)
    );
}
