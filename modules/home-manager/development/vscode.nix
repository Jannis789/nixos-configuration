{ config, pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        ms-python.python
        ms-vscode.cpptools
        esbenp.prettier-vscode
        jnoortheen.nix-ide
        catppuccin.catppuccin-vsc
      ];

      userSettings = {
        "editor.fontSize" = 13;
        "workbench.colorTheme" = "Catppuccin Mocha";
      };
    };
  };
}
