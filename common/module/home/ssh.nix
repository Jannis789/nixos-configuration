{ lib, secrets, ... }:
{
  # ponytail: home.file kann hier kein mode mehr — Dateien wären read-only
  # Store-Symlinks (chmod scheitert). Keys direkt im Aktivierungsskript schreiben.
  home.activation.sshKeys = lib.mkAfter ''
    rm -f "$HOME/.ssh/lannitz" "$HOME/.ssh/lannitz.pub" "$HOME/.ssh/arbeit" "$HOME/.ssh/arbeit.pub"
    umask 077
    cat > "$HOME/.ssh/lannitz" <<'EOF'
${secrets.SSH_KEYS.lannitz.private}
EOF
    chmod 600 "$HOME/.ssh/lannitz"
    cat > "$HOME/.ssh/lannitz.pub" <<'EOF'
${secrets.SSH_KEYS.lannitz.public}
EOF
    chmod 644 "$HOME/.ssh/lannitz.pub"
    cat > "$HOME/.ssh/arbeit" <<'EOF'
${secrets.SSH_KEYS.arbeit.private}
EOF
    chmod 600 "$HOME/.ssh/arbeit"
    cat > "$HOME/.ssh/arbeit.pub" <<'EOF'
${secrets.SSH_KEYS.arbeit.public}
EOF
    chmod 644 "$HOME/.ssh/arbeit.pub"
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
