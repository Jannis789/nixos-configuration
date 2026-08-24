{ config, lib, pkgs, ... }:

let
  extensions = [
    "ms-python.python"
    "ms-python.debugpy"
    "ms-python.vscode-pylance"
    "ms-python.vscode-python-envs"
    "jnoortheen.nix-ide"
    "bbenoist.nix"
    "catppuccin.catppuccin-vsc"
    "catppuccin.catppuccin-vsc-icons"
    "rust-lang.rust-analyzer"
    "esbenp.prettier-vscode"
    "redhat.vscode-xml"
    "bodil.blueprint-gtk"
    "dracula-theme.theme-dracula"
    "illixion.vscode-vibrancy-continued"
    "vscjava.vscode-java-pack"
    "vscjava.vscode-java-debug"
    "vscjava.vscode-java-dependency"
    "vscjava.vscode-java-test"
    "vscjava.vscode-maven"
    "vscjava.vscode-gradle"
    "vscjava.vscode-spring-initializr"
    "visualstudioexptteam.vscodeintellicode"
    "ms-vscode.cpptools"
    "ms-vscode.cpptools-extension-pack"
    "ms-vscode.cmake-tools"
    "vadimcn.vscode-lldb"
    "ms-dotnettools.vscode-dotnet-runtime"
  ];

  extPkg =
    name:
    if lib.hasAttrByPath (lib.splitString "." name) pkgs.vscode-extensions then
      lib.attrByPath (lib.splitString "." name) null pkgs.vscode-extensions
    else
      throw "vscode extension '${name}' existiert nicht in pkgs.vscode-extensions — bitte aus der Liste entfernen oder Paket ergänzen";
in
{
  programs.vscodium = {
    enable = true;
    profiles.default = {
      extensions = map extPkg extensions;
      userSettings = {
        "workbench.sideBar.location" = "right";
        "workbench.colorTheme" = "Catppuccin Mocha";
        "workbench.iconTheme" = "catppuccin-mocha";
        "terminal.integrated.gpuAcceleration" = "off";
        "terminal.integrated.fontFamily" = "FiraCode Nerd Font";
        "terminal.integrated.defaultProfile.osx" = "zsh";
        "terminal.integrated.shellIntegration.enabled" = true;
        "workbench.editor.explorerKind" = "external";
        "editor.macOptionIsMeta" = true;
        "window.systemColorTheme" = "dark";
        "window.autoDetectColorScheme" = false;
        "window.titleBarStyle" = "custom";
        "editor.fontSize" = 12;
        "editor.fontFamily" = "FiraCode Nerd Font";
        "[nix].editor.defaultFormatter" = "jnoortheen.nix-ide";
      };
    };
  };
}
