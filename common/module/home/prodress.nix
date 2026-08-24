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
    enableDefaultConfig = false;
    settings = {
      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };
      "test" = {
        HostName = "frogstar.prodress.vpn";
        User = "prodress";
      };
      "shop20a" = {
        HostName = "shop20a.prodress-updates.de";
        User = "proshop";
      };
      "22c" = {
        HostName = "asp22c.prodress-updates.de";
        User = "prodress";
      };
      "24a" = {
        HostName = "asp24a.prodress.vpn";
        User = "prodress";
      };
      "24b" = {
        HostName = "asp24b.prodress.vpn";
        User = "prodress";
      };
      "25a" = {
        HostName = "asp25a.prodress.vpn";
        User = "prodress";
      };
      "26a" = {
        HostName = "asp26a.prodress.vpn";
        User = "prodress";
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
