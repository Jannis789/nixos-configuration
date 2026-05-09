{
  config,
  pkgs,
  lib,
  ...
}:

let
  zenBrowserProfiles = {
    default = {
      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
        DisablePocket = true;
        OverrideFirstRunPage = "";
        OverridePostUpdatePage = "";
        DontCheckDefaultBrowser = true;
        DisplayBookmarksToolbar = "never";
        DisplayMenuBar = "default-off";
        SearchBar = "unified";
        NoDefaultBookmarks = true;
        OfferToSaveLoginsDefault = false;
        PasswordManagerEnabled = false;
      };
      profiles.default = {
        extensions = { };
        settings = {
          "zen.view.sidebar-expanded" = true;
          "zen.tabs.show-newtab-vertical" = true;
          "zen.view.use-single-toolbar" = false;
          "zen.theme.use-sysyem-colors" = true;
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "extensions.webextensions.ExtensionStorageIDB.enabled" = true;
          "browser.uiCustomization.state" = ''
            {
              "placements": {
                "widget-overflow-fixed-list": [],
                "unified-extensions-area": [
                  "chrome-gnome-shell_gnome_org-browser-action",
                  "jid1-niffy2ca8fy1tg_jetpack-browser-action"
                ],
                "nav-bar": [
                  "back-button",
                  "forward-button",
                  "stop-reload-button",
                  "customizableui-special-spring1",
                  "vertical-spacer",
                  "urlbar-container",
                  "unified-extensions-button",
                  "brandon_subdavis_com-browser-action",
                  "_e4c6eef1-8b3b-4daa-8757-707702e7528d_-browser-action",
                  "addon_darkreader_org-browser-action",
                  "amptra_keepa_com-browser-action",
                  "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action",
                  "ublock0_raymondhill_net-browser-action",
                  "adguardadblocker_adguard_com-browser-action",
                  "jid1-mnnxcxisbpnsxq_jetpack-browser-action"
                ],
                "toolbar-menubar": [
                  "menubar-items"
                ],
                "TabsToolbar": [
                  "tabbrowser-tabs"
                ],
                "vertical-tabs": [],
                "PersonalToolbar": [
                  "personal-bookmarks"
                ],
                "zen-sidebar-top-buttons": [
                  "zen-toggle-compact-mode"
                ],
                "zen-sidebar-foot-buttons": [
                  "downloads-button",
                  "zen-workspaces-button",
                  "zen-create-new-button"
                ]
              },
              "seen": [
                "brandon_subdavis_com-browser-action",
                "_e4c6eef1-8b3b-4daa-8757-707702e7528d_-browser-action",
                "addon_darkreader_org-browser-action",
                "adguardadblocker_adguard_com-browser-action",
                "amptra_keepa_com-browser-action",
                "chrome-gnome-shell_gnome_org-browser-action",
                "jid1-mnnxcxisbpnsxq_jetpack-browser-action",
                "jid1-niffy2ca8fy1tg_jetpack-browser-action",
                "ublock0_raymondhill_net-browser-action",
                "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action",
                "developer-button",
                "screenshot-button"
              ],
              "dirtyAreaCache": [
                "unified-extensions-area",
                "nav-bar",
                "vertical-tabs",
                "zen-sidebar-foot-buttons",
                "toolbar-menubar",
                "TabsToolbar",
                "PersonalToolbar",
                "zen-sidebar-top-buttons"
              ],
              "currentVersion": 23,
              "newElementCount": 6
            }
          '';
        };
        search = {
          force = true;
          default = "ddg";
          order = [
            "ddg"
            "google"
          ];
          engines = {
            "Nix Packages" = {
              urls = [
                {
                  template = "https://search.nixos.org/packages";
                  params = [
                    {
                      name = "type";
                      value = "packages";
                    }
                    {
                      name = "channel";
                      value = "unstable";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };
            "NixOS Wiki" = {
              urls = [ { template = "https://nixos.wiki/index.php?search={searchTerms}"; } ];
              icon = "https://nixos.wiki/favicon.png";
              updateInterval = 24 * 60 * 60 * 1000;
              definedAliases = [ "@nw" ];
            };
            "bing".metaData.hidden = true;
            "google".metaData.alias = "@g";
          };
        };
      };
    };
  };

  zenBrowserTheme = config.zen-browser.theme;
  zenBrowserAccent = config.zen-browser.accent;
  themeLower = lib.toLower zenBrowserTheme;
  zenTheme = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "zen-browser";
    rev = "main";
    sha256 = "0ynm3rvhbgcnyq664hk03wa87w81s3b9xi3rk4qxqhyl59jhpivi";
  };
  themePath = "${zenTheme}/themes/${zenBrowserTheme}/${zenBrowserAccent}";
  logoFile = "${themePath}/zen-logo-${themeLower}.svg";

  zenBrowserProfileName = config.zen-browser.profile;
in
{
  options.zen-browser = {
    profile = lib.mkOption {
      type = lib.types.str;
      default = "default";
    };
    theme = lib.mkOption {
      type = lib.types.str;
      default = "Mocha";
    };
    accent = lib.mkOption {
      type = lib.types.str;
      default = "Lavender";
    };
  };

  config = {
    programs.zen-browser = zenBrowserProfiles.${zenBrowserProfileName} // {
      enable = true;
    };

    home.activation.installZenTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ~/.zen/default
      profile_dir=~/.zen/default
      log_file=~/.zen/zen-browser-install.log

      log() {
        echo "$(date) - $1" >> $log_file
      }

      log "Zen Browser Theme Installation started"

      if [ -d "$profile_dir" ]; then
        log "Profile directory exists: $profile_dir"

        mkdir -p "$profile_dir/chrome"
        log "Created chrome directory at $profile_dir/chrome"

        cp -rf ${themePath}/userChrome.css "$profile_dir/chrome/userChrome.css"
        log "Copied userChrome.css"

        cp -rf ${themePath}/userContent.css "$profile_dir/chrome/userContent.css"
        log "Copied userContent.css"

        cp -rf ${logoFile} "$profile_dir/chrome/zen-logo-${themeLower}.svg"
        log "Copied zen-logo-${themeLower}.svg"
      else
        log "Profile directory does not exist: $profile_dir"
      fi

      log "Zen Browser Theme Installation finished"
    '';
  };
}
