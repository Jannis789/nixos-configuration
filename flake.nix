{
  description = "NixOS Multi-Host Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Local secrets directory (git submodule).
    # Uses `git+file:` with submodules=1 so Nix resolves the submodule correctly.
    # Changed from `path:` because newer Nix (≥2.18) checks git tracking even
    # with path: fetchers, and submodule index-pointer divergence causes
    # "not tracked by Git" errors.
    secrets = {
      url = "git+file:./secrets?submodules=1";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim.url = "github:Jannis789/nixvim?ref=main";

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    hermes-agent.url = "github:NousResearch/hermes-agent";

    # ── Homebrew (macOS) ───────────────────────────────────────────
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

    # ── nix-darwin (für diesen Mac) ─────────────────────────────────────
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
      ...
    }@inputs:
    let
      mkHost = import ./lib/mkHost.nix { inherit inputs nixpkgs home-manager; };
      mkDarwinHost = import ./lib/mkDarwinHost.nix {
        inherit (inputs) nix-homebrew;
        inherit inputs nixpkgs home-manager nix-darwin;
      };

      # ── NixOS Hosts ─────────────────────────────────────────────────────
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

      # ── Darwin Hosts ────────────────────────────────────────────────────
      darwinHosts = {
        darwin = {
          system = "aarch64-darwin";
          userName = "jrustige";
        };
      };
    in
    nixpkgs.lib.foldl' nixpkgs.lib.recursiveUpdate { } (
      # NixOS configurations
      (map (hostName: mkHost hostName hosts.${hostName}) (builtins.attrNames hosts))
      # Darwin configurations
      ++ (map (hostName: mkDarwinHost hostName darwinHosts.${hostName}) (builtins.attrNames darwinHosts))
    );
}
