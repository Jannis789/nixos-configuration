{ }:
let
  vscode-insiders = final: prev: {
    vscode-insiders = (prev.vscode.override { isInsiders = true; }).overrideAttrs (oldAttrs: {
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
    });
  };

  helium = final: prev: {
    helium = final.callPackage ./packages/helium.nix { };
  };

  hanabi = final: prev: {
    gnomeExtensions = prev.gnomeExtensions // {
      hanabi = final.callPackage ./packages/hanabi.nix { };
    };
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

  cockpit-nerdfont = final: prev: {
    cockpit = prev.cockpit.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        FONT_DIR=$out/share/cockpit/static
        cp ${final.nerd-fonts.fira-code}/share/fonts/truetype/NerdFonts/FiraCode/FiraCodeNerdFont-Regular.ttf $FONT_DIR/
        cp ${final.nerd-fonts.fira-code}/share/fonts/truetype/NerdFonts/FiraCode/FiraCodeNerdFont-Bold.ttf $FONT_DIR/

        TJS=$out/share/cockpit/systemd/terminal.js.gz
        zcat $TJS |
          sed -e 's/fontFamily:"Menlo, Monaco, Consolas, monospace"/fontFamily:"FiraCode Nerd Font, Menlo, Monaco, Consolas, monospace"/' \
              -e 's|this.wrapper_element=document.createElement("div")|document.fonts.ready.then(()=>{this.terminal.clearTextureAtlas();this.terminal.refresh(0,this.terminal.rows-1)});this.wrapper_element=document.createElement("div")|' |
          gzip -9 > $TJS.tmp && mv $TJS.tmp $TJS

        TCS=$out/share/cockpit/systemd/terminal.css.gz
        zcat $TCS | cat - <(echo '@font-face{font-family:"FiraCode Nerd Font";src:url("/cockpit/static/FiraCodeNerdFont-Regular.ttf") format("truetype");font-weight:400;font-display:block}@font-face{font-family:"FiraCode Nerd Font";src:url("/cockpit/static/FiraCodeNerdFont-Bold.ttf") format("truetype");font-weight:700;font-display:block}') | gzip -9 > $TCS.tmp && mv $TCS.tmp $TCS
      '';
    });
  };

  ocr-deu = final: prev: {
    gnomeExtensions = prev.gnomeExtensions // {
      native-screenshot-ui-ocr-extended = prev.gnomeExtensions.native-screenshot-ui-ocr-extended.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace ocrProcessor.js \
            --replace "['tesseract', filePath, 'stdout']" "['tesseract', filePath, 'stdout', '-l', 'deu+eng']"
        '';
      });
    };
  };
in
{
  inherit
    vscode-insiders
    helium
    hanabi
    epiphany-webext
    cockpit-nerdfont
    ocr-deu
    ;
}
