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

    starship.enable = true;
    atuin.enable = true;
  };
}
