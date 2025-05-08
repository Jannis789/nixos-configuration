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
        ms-python.debugpy 
        ms-python.vscode-pylance
        redhat.vscode-xml
        bodil.blueprint-gtk
      ];

      userSettings = {
        "editor.fontSize" = 12;
        "editor.fontFamily" = "FiraCode Nerd Font";
        "workbench.colorTheme" = "Catppuccin Mocha";
      };
    };
  };
}
