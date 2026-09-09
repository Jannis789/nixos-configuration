{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Host-overridebare pi-Defaults (z.B. darwin: github-copilot).
  # Liegen hier als eigene Option, damit hosts/darwin nur Provider/Model
  # tauscht, ohne packages/theme/contextPrune zu duplizieren — und ohne
  # programs.pi-coding-agent.settings zu setzen (das wuerde das
  # Modul-managed settings.json reaktivieren und mit home.file force=true
  # kollidieren).
  options.piAgent = {
    defaultProvider = lib.mkOption {
      type = lib.types.str;
      default = "nous";
    };
    defaultModel = lib.mkOption {
      type = lib.types.str;
      default = "~deepseek/deepseek-v4-flash-latest";
    };
  };

  config = {
    # ponytail: settings.json bewusst NICHT deklarativ setzen.
    # pi schreibt ~/.pi/agent/settings.json zur Laufzeit selbst (theme,
    # contextPrune, package-Installs). Wuerde home-manager die Datei als
    # read-only Store-Symlink verwalten (settings != {}), koennte pi sie nicht
    # mehr schreiben UND home-manager blockt jeden rebuild mit
    # "Existing file would be clobbered". Laufzeit-Datei ist Quelle der Wahrheit.
    programs.pi-coding-agent = {
      enable = true;

      # settings.json verwaltet NICHT das Modul (dessen .source-Symlink ist
      # read-only und kollidiert mit pi's Laufzeitdatei), sondern home.file mit
      # force = true weiter unten. So kann pi zur Laufzeit schreiben UND der
      # rebuild stellt den deklarativen Stand wieder her. Deklarativ gewinnt.
    };

    # --- pi settings.json DEKLARATIV (Quelle der Wahrheit) ---
    # home-manager legt die Datei an; force = true ueberschreibt sie bei jedem
    # switch. Pi darf sie zur Laufzeit aendern, der naechste rebuild stellt den
    # deklarativen Stand wieder her. Deinstallierst du Extensions, holt ein
    # rebuild sie zurueck — das ist das gewuenschte Sicherheitsnetz.
    home.file.".pi/agent/settings.json" = {
      text = builtins.toJSON {
        defaultModel = config.piAgent.defaultModel;
        defaultProvider = config.piAgent.defaultProvider;
        lastChangelogVersion = "0.80.10";
        packages = [
          "npm:@pi-unipi/memory"
          "npm:@dietrichgebert/ponytail"
          "npm:context-mode"
          "npm:pi-lens"
          "npm:pi-vscode-context"
          "npm:pi-mcp-adapter"
          "npm:pi-web-access"
          "npm:bigpowers"
          "npm:pi-fabric"
          "npm:@firstpick/pi-extension-nixos-wiki-local"
          "npm:betterwright"
          "npm:@xynogen/pix-sudo"
          "npm:pi-quiver"
          "npm:pi-cohort"
          "npm:pi-condense"
          "npm:pi-gauntlet"
          "npm:pi-tool-repair"
        ];
        theme = "violet-breakwater";
        contextPrune = {
          enabled = true;
          showPruneStatusLine = true;
          summarizerModel = "default";
          summarizerThinking = "default";
          pruneOn = "agent-message";
          batchingMode = "turn";
          quietOversizedSkips = false;
          minBatchChars = 1000;
          recoveryGraceTurns = 3;
          summarizerIdleTimeoutMs = 20000;
          summarizerMaxTimeoutMs = 180000;
          protectedTools = [ ];
          protectedPaths = [ "**/skills/**/*.md" ];
          chainCompression = {
            enabled = true;
            rollingWindow = 3;
            stripFinalAssistantThinking = true;
            fuseRangeSummary = true;
          };
          purgeErrors = {
            enabled = true;
            cooldownTurns = 2;
            minArgChars = 500;
          };
          dedupByContentHash = true;
          autoBudgetThreshold = null;
          spillThreshold = 65536;
          spillPreviewBytes = 2048;
          budgetTurnDelta = null;
          frontierGapThresholdTokens = null;
        };
      };
      force = true;
    };

    # betterwright direkt aufrufbar: Wrapper ins Profil (~/.nix-profile/bin,
    # liegt im Agent-PATH). Die KI ruft einfach "betterwright …" — kein
    # Node/Store-Pfad-Hardcode im Skill nötig.
    # NixOS-Fix an der Wurzel (NUR Linux): Der mitgelieferte BetterChromium-Fork ist ein
    # generisches Linux-Binary und läuft auf NixOS NICHT ("NixOS cannot run
    # dynamically linked executables"). BETTERWRIGHT_CHROMIUM_PATH zeigt auf das
    # nixpkgs-Chromium — supported env var, kein Symlink-Gefrickel, kein
    # Store-Pfad-Hardcode. chromium ist eh schon als pi-CLI-Dependency da.
    # ponytail: pkgs.chromium ist Linux-only — auf Darwin (aarch64) darf der
    # Ausdruck gar nicht erst evaluiert werden, sonst bricht der ganze Host.
    home.packages = [
      # pi spawnet `npm` von PATH, um Pakete (~/.pi/agent/npm) zu installieren.
      # Ohne nodejs hier: "spawn npm ENOENT" beim Start. nodejs enthaelt npm.
      pkgs.nodejs
      (pkgs.writeShellScriptBin "betterwright" (
        lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
          export BETTERWRIGHT_CHROMIUM_PATH=${pkgs.chromium}/bin/chromium
        ''
        + ''
          exec ${pkgs.nodejs}/bin/node ${config.home.homeDirectory}/.pi/agent/npm/node_modules/betterwright/dist/bin/betterwright.js "$@"
        ''
      ))
    ];

    # violet-breakwater-Theme (aus awesome-pi-themes) deklarativ im Repo.
    # Pi lädt Themes aus ~/.pi/agent/themes/*.json; theme-Name oben in settings.json gesetzt.
    home.file.".pi/agent/themes/violet-breakwater.json".source =
      ./pi/themes/violet-breakwater.json;

    # BetterWright-Skill deklarativ im Repo — überlebt Neuaufsetzen.
    # NICHT direkt nach ~/.pi/agent/skills schreiben: home-manager linkt den
    # Store-Pfad, ein echtes Verzeichnis dort würde den Link blockieren.
    home.file.".pi/agent/skills/betterwright-driver/SKILL.md".source =
      ./pi/betterwright-driver/SKILL.md;

    # Nous-Portal-Extension: auto-discovery der Live-Modelle via inference-api /v1/models.
    # Quelle liegt nicht in einem home-manager-Modul, sondern als plain JS unter
    # common/3rd-party/ — pi lädt alles unter ~/.pi/agent/extensions/ automatisch.
    home.file.".pi/agent/extensions/nous-portal/index.js".source =
      ../../3rd-party/PiNousPortalExtension.js;
  };
}
