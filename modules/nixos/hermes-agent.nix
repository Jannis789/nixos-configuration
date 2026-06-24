# modules/nixos/hermes-agent.nix
#
# Hermes-Agent NixOS Service. Provider-/Model-Konfiguration
# lebt in modules/hermes-config.nix (Single Source of Truth).
{ config, lib, pkgs, inputs, ... }:

let
  hermesCfg = import ../hermes-config.nix { secrets = inputs.secrets; };
in
{
  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    extraDependencyGroups = [ "anthropic" ];

    settings = hermesCfg.hermesConfig;

    environment = hermesCfg.envKeys;
  };
}
