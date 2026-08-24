{ }:
let
  vscodium = final: prev: {
    vscodium = prev.vscodium.overrideAttrs (old: {
      pname = "vscodium";
      version = "1.126.04518-insider";
      vscodeVersion = "1.126.0";
      libraryName = "vscodium";
      longName = "VSCodium";
      shortName = "VSCodium";
      executableName = "codium";
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.jq ];
      src =
        if final.stdenv.hostPlatform.isDarwin then
          prev.fetchurl {
            name = "VSCodium-darwin-arm64-1.126.04518-insider.zip";
            url = "https://github.com/VSCodium/vscodium-insiders/releases/download/1.126.04518-insider/VSCodium-darwin-arm64-1.126.04518-insider.zip";
            sha256 = "aca99669637582a8d5c5b9050a9f53ff1fdbdd20cac7c219d62467739e55db5d";
          }
        else
          prev.fetchurl {
            name = "VSCodium-linux-x64-1.126.04518-insider.tar.gz";
            url = "https://github.com/VSCodium/vscodium-insiders/releases/download/1.126.04518-insider/VSCodium-linux-x64-1.126.04518-insider.tar.gz";
            sha256 = "ffef9903b148c4c1c7a3a67ccf98e95cd2b0d39f89b6345e3fb374c9e1f6a8b0";
          };
      # Insiders nutzt eigene Pfade (.vscodium-insiders / "VSCodium - Insiders");
      # auf Stable-Pfade patchen, damit HM's programs.vscodium-Modul unverändert korrekt schreibt.
      # (postInstall, weil postPatch relativ zum sourceRoot läuft und den Zip-Wrapper nicht findet)
      postInstall =
        (old.postInstall or "")
        + (
          if final.stdenv.hostPlatform.isDarwin then
            ''
              PJ="$out/Applications/VSCodium.app/Contents/Resources/app/product.json"
              jq '.dataFolderName = ".vscode-oss" | .nameShort = "VSCodium" | .nameLong = "VSCodium"' "$PJ" > "$PJ.tmp" && mv "$PJ.tmp" "$PJ"
              # Zip enthält bin/codium-insiders, installPhase verlinkt aber bin/codium -> bin/codium
              ln -sfn "$out/Applications/VSCodium.app/Contents/Resources/app/bin/codium-insiders" "$out/bin/codium"
              # Insiders-Zip ist nicht korrekt signiert; adhoc neu signieren, sonst verweigert macOS den Start
              /usr/bin/codesign --force --deep --sign - "$out/Applications/VSCodium.app"
            ''
          else
            ''
              PJ="$out/lib/vscodium/resources/app/product.json"
              jq '.dataFolderName = ".vscode-oss" | .nameShort = "VSCodium" | .nameLong = "VSCodium"' "$PJ" > "$PJ.tmp" && mv "$PJ.tmp" "$PJ"
            ''
        );
    });
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
    vscodium
    helium
    hanabi
    rewaita
    epiphany-webext
    ;
}
