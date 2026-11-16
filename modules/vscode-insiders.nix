{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.vscode-insiders;

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  codeDir =
    if isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/Code"
    else
      "${config.home.homeDirectory}/.config/Code";
  insidersDir =
    if isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/Code - Insiders"
    else
      "${config.home.homeDirectory}/.config/Code - Insiders";

  extensions = [
    "ms-python.python"
    "ms-python.debugpy"
    "ms-python.vscode-pylance"
    "ms-python.vscode-python-envs"
    "jnoortheen.nix-ide"
    "bbenoist.nix"
    "catppuccin.catppuccin-vsc"
    "catppuccin.catppuccin-vsc-icons"
    "rust-lang.rust-analyzer"
    "esbenp.prettier-vscode"
    "redhat.vscode-xml"
    "bodil.blueprint-gtk"
    "dracula-theme.theme-dracula"
    "illixion.vscode-vibrancy-continued"
    "vscjava.vscode-java-pack"
    "vscjava.vscode-java-debug"
    "vscjava.vscode-java-dependency"
    "vscjava.vscode-java-test"
    "vscjava.vscode-maven"
    "vscjava.vscode-gradle"
    "vscjava.vscode-spring-initializr"
    "visualstudioexptteam.vscodeintellicode"
    "ms-vscode.cpptools"
    "ms-vscode.cpptools-extension-pack"
    "ms-vscode.cmake-tools"
    "vadimcn.vscode-lldb"
    "ms-dotnettools.vscode-dotnet-runtime"
  ];

  extPkg =
    name:
    if lib.hasAttrByPath (lib.splitString "." name) pkgs.vscode-extensions then
      lib.attrByPath (lib.splitString "." name) null pkgs.vscode-extensions
    else
      throw "vscode extension '${name}' existiert nicht in pkgs.vscode-extensions — bitte aus der Liste entfernen oder Paket ergänzen";
  resolvedExtensions = map extPkg extensions;

  marketplaceExtensions = map pkgs.vscode-utils.extensionFromVscodeMarketplace [
    {
      name = "git-tree-compare";
      publisher = "letmaik";
      version = "1.20.0";
      hash = "sha256-RoTj1ORmYnapsXHx3x4kafa7rWeRKPlKofD/pa8GbCQ=";
    }
    {
      name = "vscode-boot-dev-pack";
      publisher = "vmware";
      version = "0.2.2";
      hash = "sha256-4Sh/4zGPBGU8XwnLEt8lf9o9i3Ggjz9xsXLHcH4LKEw=";
    }
  ];

  settings = {
    "workbench.sideBar.location" = "right";
    "workbench.colorTheme" = "Catppuccin Mocha";
    "workbench.iconTheme" = "catppuccin-mocha";
    "terminal.integrated.gpuAcceleration" = "off";
    "terminal.integrated.fontFamily" = "FiraCode Nerd Font";
    "terminal.integrated.defaultProfile.osx" = "zsh";
    "terminal.integrated.shellIntegration.enabled" = true;
    "workbench.editor.explorerKind" = "external";
    "editor.macOptionIsMeta" = true;
    "window.systemColorTheme" = "dark";
    "window.autoDetectColorScheme" = false;
    "window.titleBarStyle" = "custom";
    "editor.fontSize" = 12;
    "editor.fontFamily" = "FiraCode Nerd Font";
    "[nix].editor.defaultFormatter" = "jnoortheen.nix-ide";
  };
in
{
  options.programs.vscode-insiders = {
    enable = lib.mkEnableOption "VS Code (Insiders-Wrapper)";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.vscode-insiders;
      description = "VS Code binary. Per-Host wählbar (z.B. Insiders-Overlay).";
    };
    serveWeb = {
      enable = lib.mkEnableOption "Web-UI via serve-web (VS Code im Browser, hinter nginx+Authelia)";
      port = lib.mkOption {
        type = lib.types.port;
        default = 8506;
        description = "Loopback-Port des serve-web-Dienstes (muss zur nginx-location passen).";
      };
      serverBasePath = lib.mkOption {
        type = lib.types.str;
        default = "/vscode";
        description = "Pfad, unter dem serve-web die Web-UI ausliefert (muss exakt der nginx-location entsprechen, ohne trailing slash).";
      };
      defaultFolder = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Ordner, der ohne URL-Parameter im Browser geöffnet wird.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = cfg.package;
      profiles.default.extensions = resolvedExtensions ++ marketplaceExtensions;
      profiles.default.userSettings = settings;
    };

   
   
   
    systemd.user.services.vscode-insiders-web = lib.mkIf cfg.serveWeb.enable {
      Unit = {
        Description = "VS Code Insiders Web-UI (serve-web)";
      };
      Service = {
        ExecStart = toString (
          [
            "${cfg.package}/bin/code-insiders"
            "serve-web"
            "--host" "127.0.0.1"
            "--port" (toString cfg.serveWeb.port)
            "--server-base-path" cfg.serveWeb.serverBasePath
            "--server-data-dir" "${config.home.homeDirectory}/.local/share/vscode-insiders-web"
            "--without-connection-token"
            "--accept-server-license-terms"
            "--disable-telemetry"
          ]
          ++ lib.optionals (cfg.serveWeb.defaultFolder != null) [
            "--default-folder" cfg.serveWeb.defaultFolder
          ]
        );
       
       
       
       
       
       
       
       
        ExecStartPre = toString ([
          "${pkgs.python3}/bin/python3"
          "${pkgs.writeText "vscode-web-seed.py" ''
            import json, os, glob
            home = os.path.expanduser("~")
            D = home + "/.local/share/vscode-insiders-web"
            ext = D + "/extensions"
            os.makedirs(ext, exist_ok=True)
            os.makedirs(D + "/data/User", exist_ok=True)
            settings = json.loads(${builtins.toJSON (builtins.toJSON settings)})
            open(D + "/data/User/settings.json", "w").write(json.dumps(settings))
            entries = json.load(open(home + "/.vscode-insiders/extensions/extensions.json"))
            for l in glob.glob(ext + "/*"):
                if os.path.islink(l):
                    os.unlink(l)
            reg_path = ext + "/extensions.json"
            reg = json.load(open(reg_path)) if os.path.exists(reg_path) else []
            # manuell (Marketplace) installierte Extensions behalten: echte
            # Verzeichnisse, die noch existieren
            keep = [
                e for e in reg
                if os.path.isdir(e["location"]["path"])
                and not os.path.islink(e["location"]["path"])
            ]
            out = list(keep)
            for e in entries:
                name = os.path.basename(e["location"]["path"])
                target = os.path.realpath(e["location"]["path"])
                if not os.path.isdir(target):
                    raise SystemExit("Extension-Ordner fehlt: " + name)
                os.symlink(target, ext + "/" + name)
                ne = dict(e)
                ne["location"] = {"$mid": 1, "path": ext + "/" + name, "scheme": "file"}
                ne["relativeLocation"] = name
                out.append(ne)
            json.dump(out, open(reg_path, "w"))
          ''}"
        ]);
        Environment = [
         
         
         
         
          "NIX_LD=${pkgs.stdenv.cc.bintools.dynamicLinker}"
          "NIX_LD_LIBRARY_PATH=${lib.makeLibraryPath [ (pkgs.lib.getLib pkgs.stdenv.cc.cc) pkgs.zlib ]}"
        ];
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "default.target" ];
    };

    home.activation.vscodeInsiders = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "${insidersDir}/User"
      ln -sfn "${codeDir}/User/settings.json" "${insidersDir}/User/settings.json"
      rm -rf "${config.home.homeDirectory}/.vscode-insiders/extensions"
      ln -sfn "${config.home.homeDirectory}/.vscode/extensions" \
        "${config.home.homeDirectory}/.vscode-insiders/extensions"
    '';
  };
}
