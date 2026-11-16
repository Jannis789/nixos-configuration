# Secrets (agenix)

Alle `*.age`-Dateien sind verschlüsselt und können ins öffentliche Git.
Beim Boot entschlüsselt root sie nach `/run/agenix/<name>` (RAM-Disk).

## Empfänger: nur dein Key "lannitz"

Alle Secrets sind **ausschließlich** an den Pubkey von `~/.ssh/lannitz` verschlüsselt
(siehe `agenix-rules.nix`). Das bedeutet:

- **`~/.ssh/lannitz` ist der Master-Key** — eine echte Datei auf diesem Rechner,
  von Nix/Git nicht verwaltet. Root liest sie beim Boot (`age.identityPaths`
  in `modules/host/agenix.nix`), um alle Secrets zu entschlüsseln.
- **Bitte extern sichern** (USB-Stick/Passwort-Manager): Geht die Platte flöten
  und der Key ist weg, sind alle Secrets unwiederbringlich verschlüsselt.
- Auf einem **neuen Rechner** zuerst `~/.ssh/lannitz` rüberkopieren — dann
  funktioniert dort `agenix` und der erste `nixos-rebuild switch` sofort.

## Neues Secret anlegen

1. **Rule** in `agenix-rules.nix` ergänzen:
   ```nix
   "secrets/<name>.age".publicKeys = [ lannitz ];
   ```
2. **Datei erzeugen** (Editor öffnet leer, Inhalt rein, speichern):
   ```bash
   agenix -e secrets/<name>.age
   ```
3. **Deklarieren** in `modules/host/agenix.nix` unter `age.secrets`:
   ```nix
   <name>.file = ../../secrets/<name>.age;
   # plus owner/group/mode, wenn nicht root die Datei lesen soll
   ```
4. **Benutzen** an der Verwendungsstelle:
   ```nix
   config.age.secrets.<name>.path   # = /run/agenix/<name>
   ```
5. **Stagen + bauen** (ungeaddete Dateien sieht das Flake nicht!):
   ```bash
   git add -A && nixos-rebuild switch --flake .#jannis
   ```

## Alltag

| Aktion | Befehl |
|---|---|
| Bearbeiten | `agenix -e secrets/<name>.age` |
| Ansehen | `agenix -d secrets/<name>.age` oder `sudo cat /run/agenix/<name>` |
| Löschen | `rm secrets/<name>.age` + Rule + Deklaration entfernen |

Der `agenix`-Befehl ist ein Wrapper und nutzt automatisch `~/.ssh/lannitz`.
