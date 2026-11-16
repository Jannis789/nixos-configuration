{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/host
  ];

  networking.hostName = "jannis";

  system.stateVersion = "26.11";
}
