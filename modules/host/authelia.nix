{ secrets, ... }:
{
  environment.etc = {
    "authelia/jwt-secret".text = secrets.AUTHELIA_JWT_SECRET;
    "authelia/storage-key".text = secrets.AUTHELIA_STORAGE_KEY;
    "authelia/users_database.yml".text = ''
      users:
        jannis:
          displayname: "Jannis"
          password: "${secrets.AUTHELIA_PASSWORD_HASH}"
          email: jannis@nix-dev.link
          groups: []
          totp_secret: ${secrets.AUTHELIA_TOTP_SECRET}
    '';
  };

  services.authelia.instances.main = {
    enable = true;
    secrets.jwtSecretFile = "/etc/authelia/jwt-secret";
    secrets.storageEncryptionKeyFile = "/etc/authelia/storage-key";
    settings = {
      theme = "auto";
      default_2fa_method = "totp";
      log.level = "info";
      server.address = "tcp://127.0.0.1:9092/authelia";
      totp.issuer = "jannis.nix-dev.link";
      authentication_backend.file = {
        path = "/etc/authelia/users_database.yml";
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
