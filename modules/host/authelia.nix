{ config, ... }:
{
  services.authelia.instances.main = {
    enable = true;
    secrets.jwtSecretFile = config.age.secrets.authelia-jwt.path;
    secrets.storageEncryptionKeyFile = config.age.secrets.authelia-storage-key.path;
    settings = {
      theme = "auto";
      default_2fa_method = "totp";
      log.level = "info";
      server.address = "tcp://127.0.0.1:9092/authelia";
      totp.issuer = "jannis.nix-dev.link";
      authentication_backend.file = {
        path = config.age.secrets.authelia-users.path;
        password.algorithm = "argon2id";
      };
      access_control = {
        default_policy = "deny";
        rules = [
          {
            domain = "jannis.nix-dev.link";
            policy = "two_factor";
          }
        ];
      };
      session.cookies = [
        {
          domain = "jannis.nix-dev.link";
          default_redirection_url = "https://jannis.nix-dev.link/";
          authelia_url = "https://jannis.nix-dev.link/authelia";
          name = "authelia_session";
          same_site = "lax";
          expiration = "1h";
          inactivity = "5m";
        }
      ];
      storage.local.path = "/var/lib/authelia-main/db.sqlite3";
      notifier.filesystem.filename = "/var/lib/authelia-main/notification.txt";
    };
  };
}
