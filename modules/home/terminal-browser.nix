{
  config,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.programs.terminal-browser;

  # Skill-Varianten aus dem Paket-Manifest (skills/manifest):
  #   agent claude .claude/skills default
  #   agent codex  .codex/skills  codex
  #   agent cursor .cursor/skills default
  #   agent gemini .gemini/skills default
  variants = {
    claude = "default";
    codex = "codex";
    cursor = "default";
    gemini = "default";
  };

  # Paket aus dem terminal-browser-Flake (extraSpecialArgs), sonst nixpkgs/Overlay
  flakePkg = args.terminalBrowserPkg or null;

  # Ergänzender Skill-Abschnitt: wird an jede SKILL.md-Variante angehängt
  # (das Store-Paket ist read-only, daher Kopie + append).
  skillSplitNote = pkgs.writeText "terminal-browser-skill-split-note.md" ''
    ## NixOS (Host jannis): nativer Split per `terminal-browser-split`

    Unter Ghostty/Linux kann dieses CLI selbst keine Splits öffnen (`--split`
    wirft "not supported inside ghostty on this platform" — siehe
    zenbu-labs/terminal-browser#61). Auf diesem Host ist deshalb
    `terminal-browser-split <url>` installiert: Es löst den NATIVEN
    Ghostty-Split des aktuellen Fensters per D-Bus aus (GAction
    split-down/split-right — derselbe interne Pfad wie ctrl+shift+e), ohne
    Fokus-Wechsel, ohne Tasten-Injektion, ohne neues Fenster.

    Die Richtung ist adaptiv nach Fenstergröße: Fenster höher als breit →
    Split nach unten, sonst → nach rechts. Danach hängt der Browser im neuen
    Pane; die Shell dort wird pausiert und nach dem Schließen des Browsers
    automatisch fortgesetzt. Steuerung wie gewohnt: `terminal-browser ls
    --all --json` für den browser key, dann `terminal-browser action
    --browser <key> -- snapshot|click|fill|eval`.
  '';

  # Kopie der jeweiligen Skill-Variante + Append des split-Abschnitts.
  # Achtung: Skills liegen unter lib/terminal-browser/skills/, NICHT /skills/.
  patchedSkill =
    variant:
    pkgs.runCommand "terminal-browser-skill-${variant}-patched" { } ''
      mkdir -p "$out"
      cp -r "${cfg.package}/lib/terminal-browser/skills/${variant}/terminal-browser"/. "$out/"
      chmod -R u+w "$out"
      cat "${skillSplitNote}" >> "$out/SKILL.md"
    '';
in
{
  options.programs.terminal-browser = {
    enable = lib.mkEnableOption "terminal-browser — Browser im Terminal mit Agent-Skill-Links";

    package = lib.mkOption {
      type = lib.types.package;
      default = if flakePkg != null then flakePkg else pkgs.terminal-browser;
      defaultText = lib.literalExpression "pkgs.terminal-browser";
      description = "terminal-browser-Paket (Upstream-Tarball, siehe terminal-browser-Flake).";
    };

    # Extra-Skill-Orte zusätzlich zum generischen ~/.agents/skills (das goose liest).
    # Das CLI-setup linkt nur, wenn das Elternverzeichnis existiert — dieser Default
    # entspricht genau dem Ist-Zustand auf diesem Host (es gibt kein ~/.cursor).
    agents = lib.mkOption {
      type = lib.types.listOf (lib.types.enum (lib.attrNames variants));
      default = [
        "claude"
        "codex"
        "gemini"
      ];
      description = "Agenten, deren skills/terminal-browser zusätzlich gelinkt wird.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package

      # tb-open: URL in einem neuen Ghostty-Fenster (einfacher Fallback).
      (pkgs.writeShellApplication {
        name = "tb-open";
        runtimeInputs = [ pkgs.ghostty ];
        text = ''
          exec ghostty -e terminal-browser open "$@"
        '';
      })

      # terminal-browser-split: KI-ausführbarer NATIVER Ghostty-Split — OHNE
      # Fokus-Wechsel, OHNE Tasten-Injektion, OHNE neues Fenster.
      # Trick: Ghostty 1.4 (GTK) exportiert je Fenster einen D-Bus-Knoten
      # /com/mitchellh/ghostty/window/<N> mit org.gtk.Actions — inklusive
      # "split-down"/"split-right", dem exakt selben internen Pfad wie
      # ctrl+shift+e bzw. ctrl+shift+o. Richtung adaptiv: Fenster höher als
      # breit → unten (window-calls GetFrameRect, fallback stty), sonst
      # rechts. Der Browser wird per PIXEL_TTY an die neue pts gehängt
      # (stdin/stdout müssen TTYs sein, sonst wirft das CLI "could not work
      # out which ghostty pane"), die Pane-Shell wird eingefroren (SIGSTOP),
      # damit sie dem Browser keine Tasten klaut, und vom Watcher beim
      # Browser-Ende wieder aufgeweicht (SIGCONT).
      (pkgs.writeShellApplication {
        name = "terminal-browser-split";
        runtimeInputs = [
          cfg.package
          pkgs.coreutils
          pkgs.findutils
          pkgs.gawk
          pkgs.glib.bin
          pkgs.gnugrep
          pkgs.procps
          pkgs.python3
          pkgs.systemd
          pkgs.util-linux
        ];
        text = ''
          URL="''${1:-about:blank}"
          die() { echo "terminal-browser-split: $*" >&2; exit 1; }

          # 1) Eigene pts + Ghostty-Vorfahrprozess finden. goose-Stdin ist oft
          #    kein tty — daher ctty via ps statt `tty`.
          MY_TTY=$(ps -o tty= -p "$$" | tr -d ' ')
          case "$MY_TTY" in
            pts/*) MYDEV="/dev/$MY_TTY" ;;
            /dev/pts/*) MYDEV="$MY_TTY" ;;
            *) die "keine pts ('$MY_TTY') — aus dem Ghostty-Fenster heraus aufrufen" ;;
          esac
          pid=$$
          GPID=""
          for _ in 1 2 3 4 5 6 7 8; do
            pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ') || true
            case "$pid" in ""|0|1) break ;; esac
            if grep -aqi ghostty "/proc/$pid/cmdline" 2>/dev/null; then GPID=$pid; break; fi
          done
          [ -n "$GPID" ] || die "kein Ghostty-Vorfahrprozess gefunden"

          # 2) D-Bus-Verbindung des Ghostty-Prozesses + Fenster-Knoten
          BUS=$(busctl --user list --no-legend 2>/dev/null | awk -v p="$GPID" '$2==p && !found {print $1; found=1}')
          [ -n "$BUS" ] || die "Ghostty-Prozess $GPID hat keine Session-Bus-Verbindung"
          mapfile -t WINS < <(gdbus introspect --session --dest "$BUS" --object-path /com/mitchellh/ghostty/window 2>/dev/null | awk '/node [0-9]+/{print $2}')
          NWINS=''${#WINS[@]}
          WIN=''${WINS[0]:-}
          [ -n "$WIN" ] || die "kein Fenster unter $BUS gefunden"
          if [ "$NWINS" -gt 1 ]; then echo "terminal-browser-split: $NWINS Fenster an $BUS — nehme window/$WIN" >&2; fi

          # 3) Richtung adaptiv: Fenster-Geometrie via window-calls (D-Bus-
          #    Extension; pid-exaktes Matching auf den Ghostty-Prozess),
          #    Fallback: eigene Pane-Größe via stty. Höhe > Breite → unten,
          #    sonst → rechts.
          DIR=right
          WID=$(gdbus call --session --dest org.gnome.Shell \
            --object-path /org/gnome/Shell/Extensions/Windows \
            --method org.gnome.Shell.Extensions.Windows.List 2>/dev/null | python3 -c "
          import sys, ast, json
          try:
            wins = json.loads(ast.literal_eval(sys.stdin.read().strip())[0])
            mine = [w for w in wins if 'ghostty' in str(w.get('wm_class')) and w.get('pid') == $GPID]
            if not mine:
              mine = [w for w in wins if 'ghostty' in str(w.get('wm_class')) and w.get('focus')]
            print(mine[0]['id'] if mine else 'none')
          except Exception:
            print('none')
          ")
          GEO=""
          if [ -n "$WID" ] && [ "$WID" != "none" ]; then
            GEO=$(gdbus call --session --dest org.gnome.Shell \
              --object-path /org/gnome/Shell/Extensions/Windows \
              --method org.gnome.Shell.Extensions.Windows.GetFrameRect "$WID" 2>/dev/null | python3 -c "
          import sys, ast, json
          try:
            d = json.loads(ast.literal_eval(sys.stdin.read().strip())[0])
            print(d['width'], d['height'])
          except Exception:
            print('none')
          ")
          fi
          if [ -n "$GEO" ] && [ "$GEO" != "none" ]; then
            # shellcheck disable=SC2086  # GEO ist bewusst "W H" (Word-Splitting)
            set -- $GEO
            if [ "$2" -gt "$1" ]; then DIR=down; fi
          else
            read -r ROWS COLS < <(stty size < "$MYDEV" 2>/dev/null) || true
            if [ "''${ROWS:-0}" -gt "''${COLS:-0}" ]; then DIR=down; fi
          fi

          # 4) Nativen Split auslösen (= ctrl+shift+e bzw. ctrl+shift+o intern)
          BEFORE=$(find /dev/pts -maxdepth 1 -name '[0-9]*' -printf '%f\n' | sort -n | tr '\n' ' ')
          gdbus call --session --dest "$BUS" \
            --object-path "/com/mitchellh/ghostty/window/$WIN" \
            --method org.gtk.Actions.Activate "split-$DIR" '[]' '{}' >/dev/null \
            || die "split-$DIR fehlgeschlagen"
          sleep 1
          NEW=""
          for p in $(find /dev/pts -maxdepth 1 -name '[0-9]*' -printf '%f\n' | sort -n); do
            case " $BEFORE " in
              *" $p "*) ;;
              *) NEW=$p ;;
            esac
          done
          [ -n "$NEW" ] || die "keine neue pts entstanden — Split fehlgeschlagen"

          # 5) Shell im neuen Pane einfrieren (klaut sonst dem Browser die
          #    Tasten). Watcher in Schritt 7 macht SIGCONT beim Browser-Ende.
          PANEPID=$(ps -eo pid=,tty=,comm= 2>/dev/null | awk -v t="pts/$NEW" '$2==t && $3~/bash|zsh|fish|nu/ && !found {print $1; found=1}')
          if [ -n "$PANEPID" ]; then kill -STOP "$PANEPID"; fi

          # 6) Browser an die neue pts hängen. stdin/stdout MÜSSEN TTYs sein
          #    (interactiveTty()-Prüfung des CLI), deshalb die Umleitungen.
          PIXEL_TTY="/dev/pts/$NEW" setsid terminal-browser open "$URL" \
            </dev/pts/"$NEW" >/dev/pts/"$NEW" 2>/dev/null &
          sleep 5
          KEY=$(terminal-browser ls --all --json 2>/dev/null | python3 -c "
          import sys, json
          try:
            bs = json.load(sys.stdin)['browsers']
            mine = [b for b in bs if b['tty'] == '/dev/pts/$NEW']
            print(mine[0]['key'] if mine else 'none')
          except Exception:
            print('none')
          ")
          if [ "$KEY" = "none" ]; then
            if [ -n "$PANEPID" ]; then kill -CONT "$PANEPID"; fi
            die "browser konnte nicht an pts/$NEW gestartet werden"
          fi

          # 7) Watcher: Browser zu → Pane-Shell weiterlaufen lassen
          # shellcheck disable=SC2016  # $KEY/$PANEPID expandieren bewusst im INNEREN bash
          KEY="$KEY" PANEPID="$PANEPID" setsid bash -c '
            while terminal-browser ls --all --json 2>/dev/null | grep -q "\"key\": \"$KEY\""; do
              sleep 2
            done
            kill -CONT "$PANEPID" 2>/dev/null
          ' </dev/null >/dev/null 2>&1 &

          echo "terminal-browser-split: Browser ($URL) im $DIR-Split-Pane (pts/$NEW, browser: $KEY, pane-shell pausiert: $PANEPID)"
        '';
      })
    ];

    # Skill-Links: generischer Ort (goose & co, wie im CLI-setup) plus die
    # optionalen Agent-Verzeichnisse mit ihrer jeweiligen Variante — jeweils
    # als gepatchte Kopie mit dem terminal-browser-split-Abschnitt.
    # window-calls-Extension als User-Symlink: wird von terminal-browser-split
    # für die adaptive Richtungs-Messung gebraucht (Fenstergröße).
    home.file = lib.mkMerge (
      [
        {
          ".agents/skills/terminal-browser".source = patchedSkill "default";

          ".local/share/gnome-shell/extensions/window-calls@domandoman.xyz".source =
            "${pkgs.gnomeExtensions.window-calls}/share/gnome-shell/extensions/window-calls@domandoman.xyz";
        }
      ]
      ++ map (agent: {
        ".${agent}/skills/terminal-browser".source = patchedSkill variants.${agent};
      }) cfg.agents
    );

    # setup-Marker nachziehen (Format: "<VERSION> <dist-root>"): Sonst läuft
    # ensureSetup() bei jedem CLI-Aufruf, hängt die HM-Links neu ein und editiert
    # Editor-Settings imperativ. Dist-Root ist, was bin/terminal-browser selbst
    # exportiert: dirname(bin)/.. = ${pkg}/lib/terminal-browser.
    home.activation.terminalBrowserSetupMarker = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      mkdir -p "$HOME/.local/state/terminal-browser"
      printf '%s %s\n' \
        "$(cat "${cfg.package}/lib/terminal-browser/VERSION")" \
        "${cfg.package}/lib/terminal-browser" \
        > "$HOME/.local/state/terminal-browser/setup-version"
    '';
  };
}
