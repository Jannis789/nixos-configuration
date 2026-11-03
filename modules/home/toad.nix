{
  config,
  lib,
  pkgs,
  ...
}:
# Toad-TUI als Frontend fuer ACP-Agents (goose ist im Agent-Katalog enthalten:
# startet `goose acp` automatisch). Lokal gepatcht: ```plantuml-Fences werden
# als Inline-Diagramm gerendert (lokales plantuml; Fallback Kroki).
# Env-Steuerung: TOAD_PLANTUML=auto|local|kroki|off, TOAD_KROKI_URL=...,
# TOAD_PLANTUML_CMD=plantuml
{
  config = {
    home.packages = [ pkgs.toad ];
  };
}
