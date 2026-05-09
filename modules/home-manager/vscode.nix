{
  config,
  lib,
  pkgs,
  ...
}:

let
  profiles = {
    default = {
      extensions =
        (with pkgs.vscode-extensions; [
          ms-python.python
          ms-vscode.cpptools
          esbenp.prettier-vscode
          jnoortheen.nix-ide
          catppuccin.catppuccin-vsc
          ms-python.debugpy
          ms-python.vscode-pylance
          redhat.vscode-xml
          bodil.blueprint-gtk
          vscjava.vscode-java-pack
        ])
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "bun-vscode";
            publisher = "oven";
            version = "0.0.29";
            sha256 = "sha256-2lsPM9j6dFZyKHBXvsotV22DW2JgCIaLyPuhCxSs42k=";
          }
          {
            name = "alpinejs";
            publisher = "picomet";
            version = "1.0.0";
            sha256 = "sha256-PbVEh7GLXKHcKufGzbpU0E7dCypsPeofi01isPlQSFI=";
          }
          {
            name = "alpine-js-intellisense";
            publisher = "adrianwilczynski";
            version = "1.2.0";
            sha256 = "sha256-Klx5ZvV06lXIJ3Q/mzq3KBjPpdROoxDkgEu7MBO+RhI=";
          }
          {
            name = "alpinejs-syntax-highlight";
            publisher = "sperovita";
            version = "1.0.1";
            sha256 = "sha256-gcRBcIxXc0Yc6pxKmPvRtBxO800Va5vhPxkCw1rjFbM=";
          }
        ];
      userSettings = {
        "editor.fontSize" = 12;
        "editor.fontFamily" = "FiraCode Nerd Font";
        "workbench.colorTheme" = "Catppuccin Mocha";
        "workbench.sideBar.location" = "right";
        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
        };
      };
    };

    minimal = {
      extensions = with pkgs.vscode-extensions; [
        ms-python.python
        jnoortheen.nix-ide
      ];
      userSettings = {
        "editor.fontSize" = 14;
        "workbench.colorTheme" = "Default Dark+";
      };
    };
  };

  profileName = config.vscode.profile;
in
{
  options.vscode.profile = lib.mkOption {
    type = lib.types.str;
    default = "default";
  };

  config.programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;
    profiles.default = profiles.${profileName};
  };
}
