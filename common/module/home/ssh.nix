{ lib, ... }:
{
  home.file = {
    ".ssh/lannitz" = {
      source = ../../../hosts/jannis/keys/lannitz;
    };
    ".ssh/lannitz.pub" = {
      source = ../../../hosts/jannis/keys/lannitz.pub;
    };
    ".ssh/arbeit" = {
      source = ../../../hosts/jannis/keys/arbeit;
    };
    ".ssh/arbeit.pub" = {
      source = ../../../hosts/jannis/keys/arbeit.pub;
    };
  };

  home.activation.sshKeyPermissions = lib.mkAfter ''
    chmod 600 "$HOME/.ssh/lannitz" "$HOME/.ssh/arbeit"
    chmod 644 "$HOME/.ssh/lannitz.pub" "$HOME/.ssh/arbeit.pub"
  '';

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
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/lannitz";
        IdentitiesOnly = true;
      };
      "git.prodressnet.de" = {
        User = "git";
        IdentityFile = "~/.ssh/arbeit";
        IdentitiesOnly = true;
      };
    };
  };
}
