{
  lib,
  osConfig,
  secrets,
  ...
}:
{
  # ~/.ssh/lannitz ist der Master-Key — echte Datei, NICHT von Nix verwaltet.
  # Der arbeit-Key kommt als age-Secret und wird per Symlink nach ~/.ssh gelegt.
  home.activation.linkSshKeys = lib.mkAfter ''
    ln -sfnT "${osConfig.age.secrets.ssh-arbeit.path}" "$HOME/.ssh/arbeit"
  '';
  home.file.".ssh/lannitz.pub".text = secrets.SSH_KEYS.lannitz.public + "\n";
  home.file.".ssh/arbeit.pub".text = secrets.SSH_KEYS.arbeit.public + "\n";

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
      "jannis.nix-dev.link" = {
        HostName = "jannis.nix-dev.link";
        User = "jannis";
        IdentityFile = "~/.ssh/lannitz";
        IdentitiesOnly = true;
      };
    };
  };
}
