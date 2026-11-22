{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    nixvim.url = "github:Jannis789/nixvim";

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    betterfox = {
      url = "github:yokoffing/Betterfox";
      flake = false;
    };

    llm-agents.url = "github:numtide/llm-agents.nix";

    # solid-skills: Agent-Skill (SOLID/TDD/Clean Code) für goose —
    # landet als Skill in ~/.agents/skills/solid (modules/solid-skills.nix)
    solid-skills = {
      url = "github:ramziddin/solid-skills";
      flake = false;
    };

    # heron (ACP-TUI, goose-Backend) oeffentlich aus dem eigenen Repo —
    # kein lokaler Pfad, ein Pin in flake.lock. nixpkgs follows, damit
    # heron gegen denselben Nixpkgs-Stand baut wie das System.
    heron = {
      url = "github:Jannis789/heron";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    epic-games-launcher = {
      url = "github:kjetteren/epic-games-launcher-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    terminal-browser.url = "path:/home/jannis/workspace/terminal-browser";

    nixos-secrets = {
      url = "path:/home/jannis/.config/nixos-secrets";
      flake = false;
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      secrets = import "${inputs.nixos-secrets}/default.nix";

      overlays = import ./overlays.nix { };

      mkHost =
        {
          system,
          configuration,
          username,
          home,
          hostOverlays ? [ ],
          extraModules ? [ ],
          extraHmSharedModules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = {
            inherit inputs secrets;
          };

          modules = [
            configuration
            home-manager.nixosModules.home-manager
          ]
          ++ extraModules
          ++ [
            {
              nixpkgs.config.allowUnfree = true;
              nixpkgs.overlays = [
                overlays."vscode-insiders"
                overlays.hanabi
                overlays.ocr-deu
                overlays.gnome-51
                inputs.terminal-browser.overlays.default
              ]
              ++ hostOverlays;

              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;

                extraSpecialArgs = {
                  inherit secrets;
                  betterfox = inputs.betterfox;
                  goosePkg = inputs.llm-agents.packages.${system}.goose-cli;
                  heronPkg = inputs.heron.packages.${system}.default;
                  solidSkills = inputs.solid-skills;
                };

                users.${username} = import home;

                sharedModules = extraHmSharedModules;
              };
            }
          ];
        };
    in
    {
      nixosConfigurations.jannis = mkHost {
        system = "x86_64-linux";
        configuration = ./hosts/jannis/configuration.nix;
        username = "jannis";
        home = ./hosts/jannis/home.nix;
        extraHmSharedModules = [ inputs.stylix.homeModules.stylix ];
        hostOverlays = [
          overlays.helium
          overlays.epiphany-webext
          overlays.cockpit-nerdfont
          overlays.grd-vnc
        ];
        extraModules = [ inputs.epic-games-launcher.nixosModules.default ];
      };
    };
}
