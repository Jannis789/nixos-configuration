{ config, lib, ... }:
{
  home.sessionVariables = {
    EXECDIR = "${config.home.homeDirectory}/hub/bin";
    EXECDIR_BASE = "${config.home.homeDirectory}/hub";
    PRODRESSCLIENTDIR = "${config.home.homeDirectory}/hub/javaclient";
  };

  home.file = {
    "workspace/sswsh.log".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/hub/sswsh.log";
    "workspace/dbrte-log".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/hub/dbrte-log";
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "test" = {
        hostname = "frogstar.prodress.vpn";
        user = "prodress";
      };
      "shop20a" = {
        hostname = "shop20a.prodress-updates.de";
        user = "proshop";
      };
      "22c" = {
        hostname = "asp22c.prodress-updates.de";
        user = "prodress";
      };
      "24a" = {
        hostname = "asp24a.prodress.vpn";
        user = "prodress";
      };
      "24b" = {
        hostname = "asp24b.prodress.vpn";
        user = "prodress";
      };
      "25a" = {
        hostname = "asp25a.prodress.vpn";
        user = "prodress";
      };
      "26a" = {
        hostname = "asp26a.prodress.vpn";
        user = "prodress";
      };
    };
  };

  home.shellAliases = {
    pmake = "${config.home.homeDirectory}/workspace/prodress/prodressnet/pdbuild";
    pmakeclean = "${config.home.homeDirectory}/workspace/prodress/prodressnet/pdbuild -t clean";

    inst22c = "ssh asp22c.prodress-updates.de -l prodress hub/bin/updater.sh -arg p -arg";
    inst24a = "ssh asp24a.prodress.vpn -l prodress hub/bin/updater.sh -arg p -arg";
    inst24b = "ssh asp24b.prodress.vpn -4 -l prodress hub/bin/updater.sh -arg p -arg";
    inst25a = "ssh asp25a.prodress.vpn -4 -l prodress hub/bin/updater.sh -arg p -arg";
    inst26a = "ssh asp26a.prodress.vpn -4 -l prodress hub/bin/updater.sh -arg p -arg";
    instTest = "ssh frogstar.prodress.vpn -l prodress testserver/bin/updater.sh -arg p -arg";

    deinst23a = "ssh asp23a.prodress.vpn -l prodress hub/bin/updater.sh -arg r -arg";
    deinst24a = "ssh asp24a.prodress.vpn -l prodress hub/bin/updater.sh -arg r -arg";
    deinst24b = "ssh asp24b.prodress.vpn -4 -l prodress hub/bin/updater.sh -arg r -arg";
    deinst25a = "ssh asp25a.prodress.vpn -4 -l prodress hub/bin/updater.sh -arg r -arg";
    deinst26a = "ssh asp26a.prodress.vpn -4 -l prodress hub/bin/updater.sh -arg r -arg";
    deinstTest = "ssh frogstar.prodress.vpn -l prodress testserver/bin/updater.sh -arg r -arg";
  };
}
