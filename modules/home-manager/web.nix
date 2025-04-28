{ lib, pkgs, inputs, ... }: {
  programs.librewolf = {
    enable = true;
    profiles.default = {
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
          {"placements":{"widget-overflow-fixed-list":[],"unified-extensions-area":["7esoorv3_alefvanoon_anonaddy_me-browser-action","addon_darkreader_org-browser-action","ublock0_raymondhill_net-browser-action","jid1-mnnxcxisbpnsxq_jetpack-browser-action","_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action"],"nav-bar":["sidebar-button","back-button","forward-button","stop-reload-button","firefox-view-button","vertical-spacer","urlbar-container","customizableui-special-spring2","save-to-pocket-button","downloads-button","fxa-toolbar-menu-button","unified-extensions-button","new-tab-button","alltabs-button"],"toolbar-menubar":["menubar-items"],"TabsToolbar":[],"vertical-tabs":["tabbrowser-tabs"],"PersonalToolbar":["personal-bookmarks"]},"seen":["7esoorv3_alefvanoon_anonaddy_me-browser-action","addon_darkreader_org-browser-action","ublock0_raymondhill_net-browser-action","jid1-mnnxcxisbpnsxq_jetpack-browser-action","_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action","developer-button"],"dirtyAreaCache":["unified-extensions-area","nav-bar","toolbar-menubar","TabsToolbar","vertical-tabs","PersonalToolbar"],"currentVersion":21,"newElementCount":3}
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
    };
  };
}
