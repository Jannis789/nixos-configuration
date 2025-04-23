{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    floorp
  ];
}
