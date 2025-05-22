{
  lib,
  pkgs,
  inputs,
  ...
}:
{
  programs.librewolf = {
    enable = true;
    profiles.default = {
      name = "Default";
      search = {
        default = "Startpage";
        force = true;
        engines = {
          google.metaData.hidden = true;
          bing.metaData.hidden = true;
          "Startpage" = {
            urls = [ { template = "https://www.startpage.com/sp/search?query={searchTerms}"; } ];
            icon = "https://www.startpage.com/sp/cdn/favicons/favicon-96x96.png";
            definedAliases = [
              "@sp"
              "@startpage"
            ];
          };
          "Noogle" = {
            urls = [ { template = "https://noogle.dev/q?term={searchTerms}"; } ];
            icon = "https://noogle.dev/favicon.png";
            definedAliases = [
              "@ng"
              "@noogle"
            ];
          };
          "Nix Documentation" = {
            urls = [ { template = "https://nix.dev/search.html?q={searchTerms}"; } ];
            icon = "https://nix.dev/_static/favicon.png";
            definedAliases = [
              "@nxd"
              "@nixdocs"
            ];
          };
          "Nix Manual" = {
            urls = [ { template = "https://nix.dev/manual/nix/latest/?search={searchTerms}"; } ];
            icon = "https://nix.dev/manual/nix/latest/favicon.svg";
            definedAliases = [
              "@nxm"
              "@nixmanual"
            ];
          };
          "Nix Packages" = {
            urls = [ { template = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}"; } ];
            icon = "https://search.nixos.org/favicon.png";
            definedAliases = [
              "@nxp"
              "@nixpackages"
            ];
          };
          "Searchix" = {
            urls = [ { template = "https://searchix.alanpearce.eu/all/search?query={searchTerms}"; } ];
            definedAliases = [
              "@sx"
              "@searchix"
            ];
          };
          "NixOS Options" = {
            urls = [ { template = "https://search.nixos.org/options?query={searchTerms}"; } ];
            icon = "https://search.nixos.org/favicon.png";
            definedAliases = [
              "@noo"
              "@nixosops"
            ];
          };
          "NixOS Wiki" = {
            urls = [ { template = "https://nixos.wiki/index.php?search={searchTerms}"; } ];
            icon = "https://nixos.wiki/favicon.png";
            definedAliases = [
              "@now"
              "@nixoswiki"
            ];
          };
          "Home Manager Options" = {
            urls = [ { template = "https://home-manager-options.extranix.com/?query={searchTerms}"; } ];
            icon = "https://home-manager-options.extranix.com/images/favicon.png";
            definedAliases = [
              "@hmo"
              "@homemmanageropts"
            ];
          };
          "Flake Parts Docs" = {
            urls = [ { template = "https://flake.parts/?search={searchTerms}"; } ];
            icon = "https://flake.parts/favicon.svg";
            definedAliases = [
              "@fpd"
              "flakepartsdocs"
            ];
          };
          "NixVim Docs" = {
            urls = [ { template = "https://nix-community.github.io/nixvim/?search={searchTerms}"; } ];
            icon = "https://nix-community.github.io/nixvim/favicon.svg";
            definedAliases = [
              "@nvd"
              "@nixvimdocs"
            ];
          };
          "Fancade Wiki" = {
            urls = [ { template = "https://www.fancade.com/wiki/gollum/search?q={searchTerms}"; } ];
            icon = "https://www.fancade.com/favicon.ico";
            definedAliases = [
              "@fcw"
              "@fancadewiki"
            ];
          };
          "Deepl" = {
            urls = [ { template = "https://www.deepl.com/en/translator#en/en/{searchTerms}"; } ];
            icon = "https://static.deepl.com/img/logo/deepl-logo-blue.svg";
            definedAliases = [
              "@dpl"
              "@deepl"
            ];
          };
          "youtube" = {
            urls = [ { template = "https://www.youtube.com/results?search_query={searchTerms}"; } ];
            icon = "https://www.youtube.com/s/desktop/fc303b88/img/logos/favicon.ico";
            definedAliases = [
              "@yt"
            ];
          };
        };
      };
      settings = {
        "intl.locale.requested" = "de,en-US";
        "extensions.autoDisableScopes" = 0;
        "browser.aboutConfig.showWarning" = false;
        "webgl.disabled" = false;
        "browser.tabs.closeWindowWithLastTab" = false;
        "browser.newtabpage.enable" = false;
        "browser.startup.homepage" = "about:newtab";
        "browser.toolbars.bookmarks.visibility" = "never";
        "layers.acceleration.force-enabled" = true;
        "sidebar.revamp" = true;
        "sidebar.revamp.round-content-area" = true;
        "sidebar.verticalTabs" = true;
        "sidebar.visibility" = "always-show";
        "sidebar.expandOnHover" = true;
        "browser.uiCustomization.state" = ''
          {"placements":{"widget-overflow-fixed-list":[],"unified-extensions-area":["7esoorv3_alefvanoon_anonaddy_me-browser-action","addon_darkreader_org-browser-action","ublock0_raymondhill_net-browser-action","jid1-mnnxcxisbpnsxq_jetpack-browser-action","_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action"],"nav-bar":["sidebar-button","back-button","forward-button","stop-reload-button","firefox-view-button","vertical-spacer","urlbar-container","customizableui-special-spring2","save-to-pocket-button","downloads-button","fxa-toolbar-menu-button","unified-extensions-button","new-tab-button","alltabs-button"],"toolbar-menubar":["menubar-items"],"TabsToolbar":[],"vertical-tabs":["tabbrowser-tabs"],"PersonalToolbar":["import-button","personal-bookmarks"]},"seen":["7esoorv3_alefvanoon_anonaddy_me-browser-action","addon_darkreader_org-browser-action","ublock0_raymondhill_net-browser-action","jid1-mnnxcxisbpnsxq_jetpack-browser-action","_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action","developer-button"],"dirtyAreaCache":["unified-extensions-area","nav-bar","toolbar-menubar","TabsToolbar","vertical-tabs","PersonalToolbar"],"currentVersion":21,"newElementCount":4}
        '';
      };
    };

    policies = {
      ExtensionSettings = {
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
        "langpack-de@firefox.mozilla.org" = {
          # de-DE language pack, older version, sould be updated in the future, the newer one was not working
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4473963/deutsch_de_language_pack-137.0.20250414.91429.xpi";
          installation_mode = "force_installed";
        };
        "jid1-MnnxcxisBPnSXQ@jetpack" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
          installation_mode = "force_installed";
        };
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          installation_mode = "force_installed";
        };
        "addon@darkreader.org" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
          installation_mode = "force_installed";
        };
      };

      Cookies.Allow = map (d: "https://${d}") [
        "github.com"
        "youtube.com"
        "reddit.com"
        "twitch.tv"
        "git.prodressnet.de"
        "nextcloud.prodress.de"
        "one.zoho.eu"
        "teams.microsoft.com"
        "accounts.google.com"
      ];
    };
  };
}
