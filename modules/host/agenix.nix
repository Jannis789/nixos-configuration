{
  inputs,
  pkgs,
  ...
}:
let
  agenixCli = inputs.agenix.packages.${pkgs.system}.default;
  # CLI-Wrapper: nutzt ~/.ssh/lannitz als Standard-Identität (age -i)
  agenixWrapped = pkgs.writeShellScriptBin "agenix" ''
    exec ${agenixCli}/bin/agenix -i "$HOME/.ssh/lannitz" "$@"
  '';
in
{
  imports = [ inputs.agenix.nixosModules.default ];

  # Root entschlüsselt beim Boot mit deinem lannitz-Key. Die dauerhafte Kopie
  # liegt in /var/lib/agenix/identity (außerhalb von /home, damit Home-Manager
  # sie nie anfassen kann). Die Datei wird aus ~/.ssh/lannitz synchronisiert —
  # und umgekehrt wird ~/.ssh/lannitz aus der Root-Kopie restauriert, falls HM
  # sie mal wegräumt.
  age.identityPaths = [ "/var/lib/agenix/identity" ];

  age.secrets = {
    # arbeit-Key für jannis (symlink von modules/ssh.nix nach ~/.ssh/arbeit).
    # lannitz selbst ist KEIN age-Secret: die Datei ~/.ssh/lannitz liegt als
    # echte Datei vor und ist der Master-Key für alles andere.
    ssh-arbeit = {
      file = ../../secrets/arbeit.age;
      owner = "jannis";
      group = "users";
      mode = "600";
    };
    # env-Datei (export-Zeilen), wird in der bashrc gesourced
    api-keys-env = {
      file = ../../secrets/api-keys-env.age;
      owner = "jannis";
      group = "users";
      mode = "600";
    };
    # kdbx-keychain (Browser-Extension + rclone): Dropbox-Zugang + Test-DB-Passwort.
    # Konsum: Build-Injection der Extension (App-Key) + rclone-Service (Phase 2).
    dropbox-keychain-env = {
      file = ../../secrets/dropbox-keychain-env.age;
      owner = "jannis";
      group = "users";
      mode = "600";
    };
    # rclone-Config (kdbx-keychain): Dropbox client_id/secret + OAuth-Token.
    # Der bisync-Service nutzt den agenix-Pfad direkt; ein Symlink unter
    # ~/.config/rclone/ (home.nix, tmpfiles) macht die Config für manuelle
    # rclone-Aufrufe verfügbar. Kein Secret mehr als Klartext in $HOME.
    rclone-kdbx-conf = {
      file = ../../secrets/rclone-kdbx-conf.age;
      owner = "jannis";
      group = "users";
      mode = "600";
    };
    # Authelia (Service läuft als authelia-main)
    authelia-jwt = {
      file = ../../secrets/authelia-jwt.age;
      owner = "authelia-main";
      group = "authelia-main";
    };
    authelia-storage-key = {
      file = ../../secrets/authelia-storage-key.age;
      owner = "authelia-main";
      group = "authelia-main";
    };
    authelia-users = {
      file = ../../secrets/authelia-users.age;
      owner = "authelia-main";
      group = "authelia-main";
    };
    # ACME (Service läuft als acme)
    cloudflare-credentials = {
      file = ../../secrets/cloudflare-credentials.age;
      owner = "acme";
      group = "acme";
    };
    # ddclient (läuft als root)
    cloudflare-token.file = ../../secrets/cloudflare-token.age;

    cockpit-origin-cert.file = ../../secrets/cockpit-origin-cert.age;
    cockpit-origin-key.file = ../../secrets/cockpit-origin-key.age;
  };

  environment.systemPackages = [
    agenixWrapped
    pkgs.age
  ];

  # Identity-Sync vor dem Entschlüsseln: ~/.ssh/lannitz <-> /var/lib/agenix/identity
  system.activationScripts.agenixIdentity.text = ''
    if [ -f /home/jannis/.ssh/lannitz ]; then
      if ! cmp -s /home/jannis/.ssh/lannitz /var/lib/agenix/identity; then
        install -d -m 0700 /var/lib/agenix
        install -m 0600 /home/jannis/.ssh/lannitz /var/lib/agenix/identity
      fi
    elif [ -f /var/lib/agenix/identity ]; then
      install -d -m 0700 -o jannis -g users /home/jannis/.ssh
      install -m 0600 -o jannis -g users /var/lib/agenix/identity /home/jannis/.ssh/lannitz
    fi
  '';
  # agenix muss NACH diesem Sync entschlüsseln
  system.activationScripts.agenixInstall.deps = [ "agenixIdentity" ];
}
