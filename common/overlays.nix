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

  # Hanabi (Live-Wallpaper) als gnomeExtension-Overlay — wie eine normale
  # Extension aus nixpkgs nutzbar: gnomeExtensions.hanabi.
  hanabi = final: prev: {
    gnomeExtensions = prev.gnomeExtensions // {
      hanabi = final.callPackage ./module/custom/hanabi.nix { };
    };
  };
  # Rewaita (Adwaita einfärben): nixpkgs hinkt hinterher — Version + src auf
  # Latest-Release gepinnt.
  # Fortune-Fix: PyPI-fortune installiert kein .dist-info, der neue
  # pythonMetadataCheckHook (26.11) bricht deshalb — Check nur für fortune aus,
  # das Modul selbst funktioniert (rewaita nutzt es für Zufallszitate).
  rewaita = final: prev:
    let
      py = prev.python3Packages.overrideScope (pyFinal: pyPrev: {
        fortune = pyPrev.fortune.overrideAttrs {
          dontCheckPythonMetadata = true;
        };
      });
    in {
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

  # Epiphany 51.beta — WebExtensions-Overhaul (WebKitWebExtension-Refactor).
  # nixpkgs' 50.4 hat die experimentelle Unterstuetzung auch, aber der neuere
  # Stand laedt Extensions robuster; zum Reinschnuppern in WebExtensions.
  epiphany-webext = final: prev: {
    epiphany = prev.epiphany.overrideAttrs (old: {
      version = "51.beta";
      # 50.4-CVE-Patches sind in 51.beta bereits enthalten
      patches = [ ];
      # neue 51.beta-Dependency (Passwort-Qualitaetspruefung)
      buildInputs = old.buildInputs ++ [ final.libpwquality ];
      src = prev.fetchurl {
        url = "mirror://gnome/sources/epiphany/51/epiphany-51.beta.tar.xz";
        hash = "sha256-JP1jMfoWjKrcNr9JFKmuXN/8nQC3ackbufza6xEZ+0M=";
      };
    });
  };
in
{
  inherit vscode-insiders helium hanabi rewaita epiphany-webext;
}
