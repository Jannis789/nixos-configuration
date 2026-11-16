{
  inputs,
  pkgs,
  ...
}:
{
  environment.systemPackages = [ inputs.nixvim.packages.${pkgs.system}.default ];
}
