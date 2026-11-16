{
  lib,
  pkgs,
  ...
}:
{
  home.activation.workspace = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ensure() {
      if [ ! -d "$HOME/workspace/$1" ]; then
        $DRY_RUN_CMD ${pkgs.git}/bin/git clone --quiet "$2" "$HOME/workspace/$1"
      fi
    }
    ensure heron git@github.com:Jannis789/heron.git
    ensure nixvim git@github.com:Jannis789/nixvim.git
  '';
}
