{ lib, ... }:
{
  # SSH-Keys deklarativ: liegen im Repo unter hosts/jannis/keys/.
  # HM-Version hat kein home.file.mode mehr — Permissions per activation.
  # ponytail: Keys-Pfad ist host-spezifisch (jannis); darwin hat eigene Keys.
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

  # SSH verweigert Keys mit zu offenen Permissions — nach dem Linken fixieren.
  home.activation.sshKeyPermissions = lib.mkAfter ''
    chmod 600 "$HOME/.ssh/lannitz" "$HOME/.ssh/arbeit"
    chmod 644 "$HOME/.ssh/lannitz.pub" "$HOME/.ssh/arbeit.pub"
  '';

  # Client-Config: lannitz = privat (github), arbeit = Firma.
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
