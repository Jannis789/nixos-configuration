{ config, lib, inputs, pkgs, ... }:
with lib; let
  cfg = config.programs.librewolf;
  firefox-addons = inputs.firefox-addons.packages.${pkgs.system};
in {
  config = mkIf cfg.enable {
    programs.librewolf = {
      profiles.default = {
        name = "Default";

        extensions = {
          packages = with firefox-addons; [
            ublock-origin
            privacy-badger
            bitwarden
            libredirect
            darkreader
            webhint
          ];
          force = true;
        };

        search = {
          default = "ddg";
          force = true;
          engines = {
            google.metaData.hidden = true;
            bing.metaData.hidden = true;
            startpage = {
              urls = singleton { template = "https://www.startpage.com/sp/search?query={searchTerms}"; };
              icon = "https://www.startpage.com/sp/cdn/favicons/favicon-96x96.png";
              definedAliases = [ "@sp" "@startpage" ];
            };
            noogle = {
              urls = singleton { template = "https://noogle.dev/q?term={searchTerms}"; };
              icon = "https://noogle.dev/favicon.png";
              definedAliases = [ "@ng" "@noogle" ];
            };
            nixdoc = {
              urls = singleton { template = "https://nix.dev/search.html?q={searchTerms}"; };
              icon = "https://nix.dev/_static/favicon.png";
              definedAliases = [ "@nxd" "@nixdocs" ];
            };
            nixmanual = {
              urls = singleton { template = "https://nix.dev/manual/nix/latest/?search={searchTerms}"; };
              icon = "https://nix.dev/manual/nix/latest/favicon.svg";
              definedAliases = [ "@nxm" "@nixmanual" ];
            };
            nixpkgs = {
              urls = singleton { template = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}"; };
              icon = "https://search.nixos.org/favicon.png";
              definedAliases = [ "@nxp" "@nixpackages" ];
            };
            searchix = {
              urls = singleton { template = "https://searchix.alanpearce.eu/all/search?query={searchTerms}"; };
              definedAliases = [ "@sx" "@searchix" ];
            };
            nixos-options = {
              urls = singleton { template = "https://search.nixos.org/options?query={searchTerms}"; };
              icon = "https://search.nixos.org/favicon.png";
              definedAliases = [ "@noo" "@nixosops" ];
            };
            nixos-wiki = {
              urls = singleton { template = "https://nixos.wiki/index.php?search={searchTerms}"; };
              icon = "https://nixos.wiki/favicon.png";
              definedAliases = [ "@now" "@nixoswiki" ];
            };
            home-manager-options = {
              urls = singleton { template = "https://home-manager-options.extranix.com/?query={searchTerms}"; };
              icon = "https://home-manager-options.extranix.com/images/favicon.png";
              definedAliases = [ "@hmo" "@homemanageropts" ];
            };
            flake-parts-docs = {
              urls = singleton { template = "https://flake.parts/?search={searchTerms}"; };
              icon = "https://flake.parts/favicon.svg";
              definedAliases = [ "@fpd" "flakepartsdocs" ];
            };
            nixvim-docs = {
              urls = singleton { template = "https://nix-community.github.io/nixvim/?search={searchTerms}"; };
              icon = "https://nix-community.github.io/nixvim/favicon.svg";
              definedAliases = [ "@nvd" "@nixvimdocs" ];
            };
            fancade-wiki = {
              urls = singleton { template = "https://www.fancade.com/wiki/gollum/search?q={searchTerms}"; };
              icon = "https://www.fancade.com/favicon.ico";
              definedAliases = [ "@fcw" "@fancadewiki" ];
            };
            deepl = {
              urls = singleton { template = "https://www.deepl.com/en/translator#en/en/{searchTerms}"; };
              icon = "https://static.deepl.com/img/logo/deepl-logo-blue.svg";
              definedAliases = [ "@dpl" "@deepl" ];
            };
          };
        };

        bookmarks = {
          force = true;
          settings = [
            {
              name = "GitHub";
              tags = [ "git" ];
              keyword = "github";
              url = "https://github.com/";
            }
          ];
        };

        settings = {
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
            {"placements":{"widget-overflow-fixed-list":[],"unified-extensions-area":["7esoorv3_alefvanoon_anonaddy_me-browser-action","addon_darkreader_org-browser-action","ublock0_raymondhill_net-browser-action","jid1-mnnxcxisbpnsxq_jetpack-browser-action","_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action"],"nav-bar":["sidebar-button","back-button","forward-button","stop-reload-button","firefox-view-button","vertical-spacer","urlbar-container","customizableui-special-spring2","save-to-pocket-button","downloads-button","fxa-toolbar-menu-button","unified-extensions-button","new-tab-button","alltabs-button"],"toolbar-menubar":["menubar-items"],"TabsToolbar":[],"vertical-tabs":["tabbrowser-tabs"],"PersonalToolbar":["personal-bookmarks"]},"seen":["7esoorv3_alefvanoon_anonaddy_me-browser-action","addon_darkreader_org-browser-action","ublock0_raymondhill_net-browser-action","jid1-mnnxcxisbpnsxq_jetpack-browser-action","_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action","developer-button"],"dirtyAreaCache":["unified-extensions-area","nav-bar","toolbar-menubar","TabsToolbar","vertical-tabs","PersonalToolbar"],"currentVersion":21,"newElementCount":3}
          '';
        };
      };

      policies = {
        Cookies.Allow = map (d: "https://${d}") [];
      };
    };
  };
}
