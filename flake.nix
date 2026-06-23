{
  description = "NixOS Multi-Host Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    "private-keys" = {
      # Indirektion: hermes-api.nix liegt physisch im `secrets/`-
      # Submodul (single-source-of-truth), aber
      # `private-keys/hermes-api.nix` ist eine HARDCOPY (kein symlink)
      # in einem NON-SUBMODULE-Verzeichnis hier im parent-Repo.
      # Begruendung: Nix's `path:`-Fetcher treated Verzeichnisse MIT
      # `.git`-Marker (egal ob submodule oder plain repo) per
      # git-archive-Semantik — er kopiert NUR HEAD-tracked Files in
      # den Store. Working-tree-untracked Files wie `secrets/hermes-
      # api.nix` waeren ueber `path:./secrets` daher nicht erreichbar
      # (Empirik: build fail mit `path '...-source/secrets/hermes-
      # api.nix' does not exist`).
      # Im `private-keys/`-Verzeichnis ist KEIN `.git`-Marker →
      # plain filesystem copy → hermes-api.nix ist im Store verfuegbar.
      # plaintext-Keys bleiben OUT OF GIT: `private-keys/` ist in
      # .gitignore, Source-of-Truth im privaten secrets-Submodul.
      # TODO spaeter: sops-nix/agenix → kein plaintext im Nix-Store,
      # decrypt-on-boot nach /run/secrets/.
      url = "path:./private-keys";
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
