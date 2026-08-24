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
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/lannitz";
        identitiesOnly = true;
      };
      "git.prodressnet.de" = {
        user = "git";
        identityFile = "~/.ssh/arbeit";
        identitiesOnly = true;
      };
    };
  };
}
