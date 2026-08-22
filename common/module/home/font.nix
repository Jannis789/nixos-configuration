{ config, lib, pkgs, ... }:
{
  # Nerd Fonts via home.packages — landen in ~/.local/share/fonts,
  # den home-manager automatisch dem fontconfig hinzufügt.
  # Family-Name (FiraCode Nerd Font) wird von Terminal/Editor direkt genutzt.
  home.packages = [ pkgs.nerd-fonts.fira-code ];
}
