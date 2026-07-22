{
  config,
  lib,
  pkgs,
  inputs,
  hermesPkgs,
  ...
}:

let
  hermesCfg = import ../../modules/hermes-config.nix { secrets = inputs.secrets; };

  yamlFormat = pkgs.formats.yaml { };
  hermesConfigYAML = yamlFormat.generate "config.yaml" hermesCfg.hermesConfig;

  # Fail-at-eval guard: if work/zsh-extra-rc is missing from the locked secrets input
  secretsWorkZshRCPath =
    if builtins.pathExists (inputs.secrets + "/work/zsh-extra-rc")
    then inputs.secrets + "/work/zsh-extra-rc"
    else throw ''
      home/darwin.nix (zshrcContent → secretsWorkZshRCPath): 
      secrets/work/zsh-extra-rc nicht im geloeckten `secrets`-Flake-
      Input-HEAD gefunden.

      Der Store-Pfad "${inputs.secrets + "/work/zsh-extra-rc"}" existiert
      nicht — Ursache ist meistens, dass die Datei im HEAD-Commit des
      `secrets`-Git-Submoduls nicht enthalten ist (z.B. nur gestaged).

      Fix:
        1. cd /Users/jrustige/Documents/nixos-configuration/secrets
        2. git status                 # Work-Verzeichnis-Status pruefen
        3. git add work/zsh-extra-rc  # bzw. "git commit" wenn schon gestaged
        4. git commit -m "Add work/zsh-extra-rc"
        5. cd /Users/jrustige/Documents/nixos-configuration
        6. nix flake update secrets   # aktualisiert flake.lock lokal
        7. cd /Users/jrustige/Documents/nixos-configuration && \
           git add flake.lock && git commit -m "Update secrets submodule pointer"
                                       # Schritt 7 nicht vergessen — sonst
                                       # bleibt flake.lock dirty und jeder
                                       # Rebuild startet mit der Warning
                                       # "Git tree ... is dirty".
        8. darwin-rebuild switch --flake .#darwin
    '';

  # Non-sensitive Zsh base config; secrets/work/zsh-extra-rc is sourced at the end
  zshrcContent = ''
    autoload -Uz compinit
    compinit

    bindkey '^I' menu-complete
    bindkey '^[^I' menu-complete-backward

    zstyle ':completion:*' list-prompt "%S%M matches%s"
    zstyle ':completion:*' menu select=0
    zstyle ':completion:*' group-name ""
    zstyle ':completion:*' verbose yes

    setopt list_packed
    setopt auto_list

    bindkey '^[[A' up-line-or-history
    bindkey '^[[B' down-line-or-history
    bindkey '^[r' atuin-up-search

    export NVM_DIR="$HOME/.nvm"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        \. "$NVM_DIR/nvm.sh"
    fi
    if [ -s "$NVM_DIR/bash_completion" ]; then
        \. "$NVM_DIR/bash_completion"
    fi

    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"

    export PATH="$HOME/.opencode/bin:$PATH"

    export GHOSTTY_CONFIG_FILE="$HOME/Library/Application Support/com.mitchellh.ghostty/config"

    source ${secretsWorkZshRCPath}
  '';
in
{
  home.username = "jrustige";
  home.homeDirectory = "/Users/jrustige";
  home.stateVersion = "25.05";

  home.sessionVariables = hermesCfg.envKeys;
  home.file.".hermes/config.yaml".source = hermesConfigYAML;

  home.packages = with pkgs; [
    inputs.nixvim.packages.${pkgs.stdenv.hostPlatform.system}.default
    btop fastfetch git wget starship atuin zoxide nixfmt
    openssh unzip tree fzf sqlite python3 nodejs ripgrep fd
  ];

  programs = {
    home-manager.enable = true;

    bash = {
      enable = true;
      bashrcExtra = ''
        export PATH="/opt/homebrew/bin:$PATH"
        export PATH="$HOME/.local/bin:$PATH"
      '';
    };

    zsh = {
      enable = true;
      # initContent replaces deprecated initExtraFirst/initExtra (HM ≥ release-25.05).
      # lib.mkBefore: PATH exports (before HM defaults — compinit, autoload)
      # lib.mkAfter:  zshrcContent (completion styles, bindings, work source)
      initContent = lib.mkMerge [
        (lib.mkBefore ''
          export PATH="/opt/homebrew/bin:$PATH"
          export PATH="$HOME/.local/bin:$PATH"
        '')
        (lib.mkAfter zshrcContent)
      ];
    };

    starship.enable = true;
    atuin.enable = true;
  };
}
