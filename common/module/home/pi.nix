{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.pi-coding-agent = {
    enable = true;
    settings = {
      lastChangelogVersion = "0.80.10";
      theme = "dark";
      defaultProvider = "nous";
      defaultModel = "~deepseek/deepseek-v4-flash-latest";

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
      ];
    };
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
    (pkgs.writeShellScriptBin "betterwright" (
      lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
        export BETTERWRIGHT_CHROMIUM_PATH=${pkgs.chromium}/bin/chromium
      '' + ''
        exec ${pkgs.nodejs}/bin/node ${config.home.homeDirectory}/.pi/agent/npm/node_modules/betterwright/dist/bin/betterwright.js "$@"
      ''
    ))
  ];

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
}
