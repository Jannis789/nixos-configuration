# Benannte Overlays — mkHost (flake.nix) wendet sie per Host an.
# vscode-insiders: alle Hosts. helium: nur NixOS (per hostOverlays).
{ }:
let
  vscode-insiders = final: prev: {
    vscode-insiders = (prev.vscode.override { isInsiders = true; }).overrideAttrs (oldAttrs:
      if final.stdenv.hostPlatform.isLinux then {
        src = builtins.fetchTarball {
          url = "https://code.visualstudio.com/sha/download?build=insider&os=linux-x64";
          sha256 = "1vakxryvpi7v8065r93pxr9lyx1gpw0389bjpsidw99snjr9r842";
        };

        version = "latest";

        buildInputs = oldAttrs.buildInputs ++ [
          prev.krb5
          prev.libsoup_3
          prev.webkitgtk_4_1
        ];
      } else {
        src = prev.fetchurl {
          url = "https://update.code.visualstudio.com/latest/darwin-arm64/insider";
          sha256 = "sha256-VfzjdQoRFBOcDuJaK+TbjVPdGFghiDtUb7qiW7ltZnU=";
        };

        sourceRoot = ".";
        version = "latest";
      });
  };

  # Custom-Paket helium (nur NixOS).
  helium = final: prev: {
    helium = final.callPackage ./module/custom/helium.nix { };
  };
in
{
  inherit vscode-insiders helium;
}
