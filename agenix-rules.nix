# Empfänger für alle Secrets: NUR dein User-Key "lannitz".
# age matcht SSH-Identitäten direkt gegen SSH-Pubkeys — keine Konvertierung nötig.
# (Das ist ein öffentlicher Key, kein Geheimnis.)
# Hinweis: ~/.ssh/lannitz (die private Datei auf diesem Rechner) ist damit der
# Master-Key — bitte extern sichern (USB/Passwort-Manager), ohne ihn sind die
# Secrets bei einem Platten-Crash unwiederbringlich weg.
let
  lannitz = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOFLkow1lN0X8m8Wc84hXx22dTEpCpcx00kevF4ieVQF";
in
{
  "secrets/arbeit.age".publicKeys = [ lannitz ];
  "secrets/api-keys-env.age".publicKeys = [ lannitz ];
  # kdbx-keychain: Dropbox App-Key/-Secret + Passwort der Test-kdbx (export-Zeilen)
  "secrets/dropbox-keychain-env.age".publicKeys = [ lannitz ];
  # rclone-Config für kdbx-keychain (Dropbox client_id/secret + OAuth-Refresh-Token);
  # ersetzt die ehemals manuell gepflegte ~/.config/rclone/rclone.conf
  "secrets/rclone-kdbx-conf.age".publicKeys = [ lannitz ];
  # KeePass-Keyfile zum echten Tresor (rotiert nie → statisch in agenix)
  "secrets/kdbx-export-key.age".publicKeys = [ lannitz ];
  # AMO API-Keys fürs web-ext sign der Firefox-Extension (unlisted self-distribution)
  "secrets/amo-sign-env.age".publicKeys = [ lannitz ];
  "secrets/authelia-jwt.age".publicKeys = [ lannitz ];
  "secrets/authelia-storage-key.age".publicKeys = [ lannitz ];
  "secrets/authelia-users.age".publicKeys = [ lannitz ];
  "secrets/cloudflare-credentials.age".publicKeys = [ lannitz ];
  "secrets/cloudflare-token.age".publicKeys = [ lannitz ];
  "secrets/cockpit-origin-cert.age".publicKeys = [ lannitz ];
  "secrets/cockpit-origin-key.age".publicKeys = [ lannitz ];
}
