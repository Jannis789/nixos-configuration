{
  description = "NixOS Multi-Host Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    secrets = {
      # Privates Git-Submodul (`secrets/`, gitignored im Host-Repo).
      # `git+file:` fetcht das Submodul als eigenes Git-Repo und kopiert
      # dessen HEAD-getrackte Files (hermes-api.nix, ssh-authorized-keys,
      # nvim-env) in den Store. WICHTIG: jede neue Secret-Datei muss im
      # Submodul committet werden, sonst ist sie fuer die Flake-Eval
      # unsichtbar (git-archive-Semantik).
      # `path:./secrets` funktioniert NICHT: der path:-Fetcher loest
      # relativ zum Parent-Flake-Store-Snapshot auf, und dort ist das
      # Submodul nur ein leerer gitlink (Inhalt nicht expandiert) →
      # `hermes-api.nix does not exist`.
      # plaintext-Keys bleiben OUT OF GIT des Host-Repos: Source-of-
      # Truth ist ausschliesslich das private secrets-Submodul.
      # TODO spaeter: sops-nix/agenix → kein plaintext im Nix-Store,
      # decrypt-on-boot nach /run/secrets/.
      url = "git+file:./secrets";
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
