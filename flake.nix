{
  description = "NixOS Multi-Host Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    secrets = {
      # `path:`-URL statt `git+file`: Nix kopiert das lokale Verzeichnis
      # 1:1 in den Store, OHNE den Git-Tracker des Submoduls zu konsultieren.
      # Damit sind untracked Files wie `hermes-api.nix` fuer die Flake-Eval
      # sichtbar — ohne dass plaintext-Kennwoerter in eine Git-History
      # wandern muessten. (Vorher: `git+file:./secrets?ref=main` warf
      # `error: Path 'secrets/hermes-api.nix' is not tracked by Git`.)
      url = "path:./secrets";
      flake = false;
    };

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
