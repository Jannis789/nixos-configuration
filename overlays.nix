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

  # Sunshine mit VIRTUAL-Quellentyp: der Portal-Backend fragt bei
  # ScreenCast.SelectSources einen virtuellen Monitor an (Portal-Wert 4)
  # statt eines physischen. Zweck: Stream-Auflösung unabhängig von den
  # Monitor-Modi. Zwei Ersetzungen, kein Patch-File nötig.
  # Rückbau: diesen Block entfernen.
  sunshine-virtual = final: prev: {
    sunshine = prev.sunshine.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace src/platform/linux/portalgrab.cpp \
          --replace-fail 'constexpr uint32_t SOURCE_TYPE_MONITOR = 1;' \
                         'constexpr uint32_t SOURCE_TYPE_MONITOR = 1;
  constexpr uint32_t SOURCE_TYPE_VIRTUAL = 4;' \
          --replace-fail 'g_variant_new_uint32(SOURCE_TYPE_MONITOR)' \
                         'g_variant_new_uint32(SOURCE_TYPE_VIRTUAL)'
      '';
    });
  };

  helium = final: prev: {
    helium = final.callPackage ./packages/helium.nix { };
  };

  selkies = final: prev: {
    selkies = final.callPackage ./packages/selkies.nix { };
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
  # gnome-remote-desktop mit VNC-Backend: upstream/nixpkgs bauen GRD seit 47
  # ohne VNC (meson: -Dvnc=false) — der Daemon lauscht dann nur auf RDP (3389)
  # und grdctl kennt keine vnc-Subcommands. Mit -Dvnc=true + libvncserver
  # kommt der klassische VNC-Server (Port 5900) zurück; Encodings inkl. Tight
  # handelt libvncserver direkt mit dem VNC-Client aus.
  grd-vnc = final: prev: {
    # libvncserver wählt beim SetEncodings-Handshake das erste Encoding aus
    # der Client-Liste als "preferred". RFB erlaubt dem Server aber jedes
    # client-angefragte Encoding — der Patch lässt Tight gewinnen, sobald
    # der Client es anbietet (auch wenn er es z. B. hinter Hextile listet).
    libvncserver = prev.libvncserver.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./packages/libvncserver-prefer-tight.patch ];
    });

    gnome-remote-desktop = prev.gnome-remote-desktop.overrideAttrs (old: {
      mesonFlags = (old.mesonFlags or [ ]) ++ [ "-Dvnc=true" ];
      buildInputs = (old.buildInputs or [ ]) ++ [ final.libvncserver ];
    });
  };

  # GNOME-51-Kompatibilität: nixpkgs baut Extensions aus extensions.gnome.org
  # und pinnt deren metadata.json. Einträge ohne "51" lädt GNOME Shell 51 als
  # OUT OF DATE nicht.
  #
  # - window-calls: upstream-Fix ist reiner Metadata-Bump (PR #58, 2026-11-18).
  # - native-screenshot-ui-ocr-extended (ocr-to-clipboard): Metadata-Bump plus
  #   Code-Fix aus upstream-PR #23 — GNOME 51 hat St.BoxLayout.vertical
  #   entfernt, daher orientation nutzen, wenn die Property existiert.
  gnome-51 = final: prev: {
    gnomeExtensions = prev.gnomeExtensions // {
      window-calls = prev.gnomeExtensions.window-calls.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          sed -i 's/"50"/"50", "51"/' metadata.json
        '';
      });

      native-screenshot-ui-ocr-extended = prev.gnomeExtensions.native-screenshot-ui-ocr-extended.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          sed -i 's/"50"/"50", "51"/' metadata.json
          substituteInPlace extension.js --replace-fail "vertical: true," \
            "...('orientation' in St.BoxLayout.prototype
                    ? { orientation: Clutter.Orientation.VERTICAL }
                    : { vertical: true }),"
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
    gnome-51
    grd-vnc
    selkies
    sunshine-virtual
    ;
}
