{ }:
let
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
  inherit helium hanabi rewaita epiphany-webext;
}
