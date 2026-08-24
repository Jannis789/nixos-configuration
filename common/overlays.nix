{ }:
let
  vscode-insiders = final: prev: {
    vscode-insiders = (prev.vscode.override { isInsiders = true; }).overrideAttrs (
      oldAttrs:
      if final.stdenv.hostPlatform.isLinux then
        {
          src = builtins.fetchTarball {
            url = "https://code.visualstudio.com/sha/download?build=insider&os=linux-x64";
            sha256 = "04d2hb4fi1r3xfkkcyqys44zfl6xhkpzbf7nlf1lv7vafh5xwp1s";
          };

          version = "latest";

          buildInputs = oldAttrs.buildInputs ++ [
            prev.krb5
            prev.libsoup_3
            prev.webkitgtk_4_1
          ];
        }
      else
        {
          src = prev.fetchurl {
            url = "https://update.code.visualstudio.com/latest/darwin-arm64/insider";
            sha256 = "sha256-nAoKFwwvJQnC40ATbNPS48FLITCsjPMTLaDbYLxgGNw=";
          };

          sourceRoot = ".";
          version = "latest";
        }
    );
  };

  helium = final: prev: {
    helium = final.callPackage ./module/custom/helium.nix { };
  };

  hanabi = final: prev: {
    gnomeExtensions = prev.gnomeExtensions // {
      hanabi = final.callPackage ./module/custom/hanabi.nix { };
    };
  };
  rewaita =
    final: prev:
    let
      py = prev.python3Packages.overrideScope (
        pyFinal: pyPrev: {
          fortune = pyPrev.fortune.overrideAttrs {
            dontCheckPythonMetadata = true;
          };
        }
      );
    in
    {
      rewaita = (prev.rewaita.override { python3Packages = py; }).overrideAttrs (old: {
        version = "1.1.6";
        src = prev.fetchFromGitHub {
          owner = "SwordPuffin";
          repo = "Rewaita";
          tag = "v1.1.6";
          hash = "sha256-ddfNsa3OWFitt38sRko7oOduAz1ydQG/+OcQNowwuMs=";
        };
      });
    };

  epiphany-webext = final: prev: {
    epiphany = prev.epiphany.overrideAttrs (old: {
      version = "51.beta";
      patches = [ ];
      buildInputs = old.buildInputs ++ [ final.libpwquality ];
      src = prev.fetchurl {
        url = "mirror://gnome/sources/epiphany/51/epiphany-51.beta.tar.xz";
        hash = "sha256-JP1jMfoWjKrcNr9JFKmuXN/8nQC3ackbufza6xEZ+0M=";
      };
    });
  };
in
{
  inherit
    vscode-insiders
    helium
    hanabi
    rewaita
    epiphany-webext
    ;
}
