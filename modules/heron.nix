{
  heronPkg,
  ...
}:
{
  # heron: eigenes ACP-TUI (Go/Bubble-Tea) mit goose als Backend.
  # Paket kommt deklarativ aus dem oeffentlichen Flake (flake.nix-Input
  # "heron", github:Jannis789/heron) — kein lokaler Pfad. goose liefert
  # modules/goose.nix (heron startet `goose acp` aus dem PATH).
  home.packages = [ heronPkg ];
}
