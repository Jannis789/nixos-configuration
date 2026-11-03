{
  description = "NixOS configuration v2 — Hosts über mkHost";

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

    cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    # Standalone-Editor-Flake: eigener Nixvim-Fork
    nixvim.url = "github:Jannis789/nixvim";

    # Theming: ein zentraler Theme-Express (base16) statt gepackter Shell-Themes
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Privacy-Overlay fuer Firefox (user.js): Fastfox/Securefox/Peskyfox
    betterfox = {
      url = "github:yokoffing/Betterfox";
      flake = false;
    };

    # Taeglich aktualisierte AI-Agent-Packages (goose-cli 1.53.0 > nixpkgs 1.28.0,
    # bringt den nativen Z.AI Coding Plan Provider mit)
    llm-agents.url = "github:numtide/llm-agents.nix";

    # Epic Games Launcher (native Linux-Preview): Epics .deb in FHS-Env,
    # taeglich aktualisiertes Upstream-Flake (Update: nix flake update epic-games-launcher)
    epic-games-launcher = {
      url = "github:kjetteren/epic-games-launcher-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # terminal-browser (Browser im Terminal) — lokaler Nix-Wrap des Upstream-Tarballs.
    # Overlay liefert pkgs.terminal-browser, das HM-Modul die Agent-Skill-Links.
    # Absolut statt "path:../terminal-browser": bei dirty git-trees löst Nix relative
    # path-inputs relativ zur Store-Kopie auf und findet das Nachbar-Repo dann nicht.
    terminal-browser.url = "path:/home/jannis/workspace/terminal-browser";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nix-darwin,
      nix-homebrew,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      secrets = import ./secrets.nix;

      overlays = import ./overlays.nix { };

      mkHost =
        {
          kind,
          system,
          configuration,
          username,
          home,
          hostOverlays ? [ ],
          extraModules ? [ ],
          extraHmSharedModules ? [ ],
        }:
        let
          isNixos = kind == "nixos";
          hmModule =
            if isNixos then home-manager.nixosModules.home-manager else home-manager.darwinModules.home-manager;
        in
        (if isNixos then nixpkgs.lib.nixosSystem else nix-darwin.lib.darwinSystem) {
          inherit system;

          specialArgs = { inherit inputs secrets; };

          modules = [
            configuration
            hmModule
          ]
          ++ extraModules
          ++ lib.optionals (!isNixos) [ nix-homebrew.darwinModules.nix-homebrew ]
          ++ [
            {
              nixpkgs.config.allowUnfree = true;
              nixpkgs.overlays = [
                overlays."vscode-insiders"
                overlays.hanabi
                overlays.toad
                # pkgs.terminal-browser für alle Hosts (rein additiv) — je Host
                # aktivierbar via programs.terminal-browser.enable (HM-Modul)
                inputs.terminal-browser.overlays.default
              ]
              ++ hostOverlays;

              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;

                extraSpecialArgs = {
                  inherit secrets;
                  # Betterfox-user.js als Store-Pfad fuer das Firefox-Profil
                  betterfox = inputs.betterfox;

                  # goose-cli 1.53.0 aus llm-agents.nix (neuer als nixpkgs 1.28.0,
                  # bringt den nativen Z.AI Coding Plan Provider mit)
                  goosePkg = inputs.llm-agents.packages.${system}.goose-cli;
                };

                users.${username} = import home;

                # Gast-Host übergibt hier z.B. das Stylix-Home-Modul
                sharedModules = extraHmSharedModules;
              };
            }
          ];
        };
    in
    {
      nixosConfigurations.jannis = mkHost {
        kind = "nixos";
        system = "x86_64-linux";
        configuration = ./hosts/jannis/configuration.nix;
        username = "jannis";
        home = ./hosts/jannis/home.nix;
        extraHmSharedModules = [ inputs.stylix.homeModules.stylix ];
        hostOverlays = [
          overlays.helium
          overlays.epiphany-webext
          overlays.cockpit-nerdfont
        ];
        # NixOS-Modul: programs.epic-games-launcher.enable (siehe hosts/jannis)
        extraModules = [ inputs.epic-games-launcher.nixosModules.default ];
      };

      darwinConfigurations.darwin = mkHost {
        kind = "darwin";
        system = "aarch64-darwin";
        configuration = ./hosts/darwin/configuration.nix;
        username = "jrustige";
        home = ./hosts/darwin/home.nix;
      };
    };
}
