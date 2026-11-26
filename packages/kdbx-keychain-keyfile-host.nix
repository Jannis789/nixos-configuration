{
  runCommand,
  writers,
}:
# Native-Messaging-Host für kdbx-keychain (ADR-010): stellt das agenix-Keyfile
# (/run/agenix/kdbx-export-key) per chrome-NM-Protokoll bereit. Das Manifest
# registrert die Extension-ID (Chrome, gepinnt via manifest-"key") und die
# Gecko-ID (Firefox) — eine Datei für beide Browser.
# Deployment:
#   Firefox: wrapper-Option nativeMessagingHosts (siehe hosts/jannis/home.nix)
#   Chrome:  home.file → ~/.config/google-chrome|chromium/NativeMessagingHosts/
let
  host = writers.writePython3Bin "kdbx-keychain-keyfile-host"
    {
      flakeIgnore = [
        "E265"
        "E501"
        "W291"
        "W292"
        "W293"
      ];
    }
    ./kdbx-keychain-keyfile-host/host.py;
in
runCommand "kdbx-keychain-keyfile-host"
  {
    meta.description = "Native-Messaging-Host: agenix-Keyfile für kdbx-keychain";
    passthru.manifest = "lib/mozilla/native-messaging-hosts/kdbx_keychain_keyfile.json";
  }
  ''
    mkdir -p $out/bin $out/lib/mozilla/native-messaging-hosts
    cp ${host}/bin/kdbx-keychain-keyfile-host $out/bin/
    cat > $out/lib/mozilla/native-messaging-hosts/kdbx_keychain_keyfile.json <<JSON
{
  "name": "kdbx_keychain_keyfile",
  "description": "liefert das agenix-Keyfile an kdbx-keychain (ADR-010)",
  "path": "$out/bin/kdbx-keychain-keyfile-host",
  "type": "stdio",
  "allowed_extensions": [ "kdbx-keychain@nix-dev.link" ],
  "allowed_origins": [ "chrome-extension://giaekmmanecjlcpifjmleemimokmeoka/" ]
}
JSON
  ''
