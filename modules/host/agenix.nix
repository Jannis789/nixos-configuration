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

  # Root entschlüsselt beim Boot mit deinem lannitz-Key (echte Datei in deinem
  # Home — root darf sie lesen). Kein Host-Key als Empfänger mehr nötig.
  age.identityPaths = [ "/home/jannis/.ssh/lannitz" ];

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
}
