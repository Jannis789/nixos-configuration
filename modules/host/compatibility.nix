{ pkgs, ... }:
{
  programs.nix-ld = {
    enable = true;
    libraries = [
      (pkgs.lib.getLib pkgs.stdenv.cc.cc)
      pkgs.zlib
    ];
  };
}
