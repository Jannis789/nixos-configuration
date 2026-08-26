---
name: betterwright-driver
description: Browser-Aufgaben via betterwright view + run (Live View, User schaut zu/lenkt, KEIN Sub-Agent). exec nur auf expliziten Wunsch. Immer lesen bei Browser-Aufgaben (Login, Formulare, Buchungen, Käufe, Seiten lesen) oder wenn der User "Browser", "Live View", "Chat", "Handoff" oder "betterwright" erwähnt.
---

# BetterWright — Browser

## Beim Skill-Load: Browser starten (one-shot, idempotent)

`run`/`view` brauchen keinen API-Key. Beim Laden des Skills sofort:

```bash
nohup betterwright view --host 127.0.0.1 > /tmp/bw-view.log 2>&1 &
sleep 3 && grep -o 'http://127.0.0.1:[0-9]*/?t=[A-Za-z0-9_-]*' /tmp/bw-view.log
```

- Läuft schon (`betterwright sessions` → `default`)? URL aus dem Log geben, nichts Neues starten.
- URL dem User VERBATIM geben (Capability-Token, wie Passwort behandeln).
- **Das ist KEINE Aufgabe.** Danach stoppen und auf die konkrete Aufgabe warten — kein Interpretieren, kein Repo-Check, keine Commits.

## Steuern: betterwright run (ein Tool-Call pro Schritt)

```bash
betterwright run -c "await page.goto('https://example.com'); return page.title()"
# → {ok:true, result:"Example Domain", session:"default"}
```

- Globals im Snippet: `page`, `snapshot`, `screenshot`, `credentials`, `human`, `controls`, `webagents`, `webmcp`.
- Session `default` persistiert — gleiche Tabs wie der Viewer, Folge-Runs machen weiter.
- Aktion + Beobachtung pro Snippet kombinieren; bei unsicherem Zustand erst lesen (`snapshot`/`innerText`), dann handeln.
- KEIN `exec`/Sub-Agent außer explizit gewünscht. exec braucht API-Key: `--api-key-env` aus secrets.nix, nie im Kommando.
- Secrets nie im Kommando. `vault show --reveal`/`copy`/`rm` verboten, `vault list` ok.
- Vor Login/Signup/Checkout: `betterwright skills show credential-manager`; vor GitHub: `github`.
- 5xx/Timeout: 30–60 s Backoff, erst dann "down".

## NixOS: Chromium-Symlink (Fork läuft nicht auf NixOS)

```bash
B=~/.betterwright/chromium/linux-x64/betterchromium
mv "$B" "$B.nixos-dead" 2>/dev/null
ln -s /nix/store/5prcsr1v91xai06jmpxxh3wh4c79h0s6-chromium-150.0.7871.181/bin/chromium "$B"
```

Nach jedem `betterwright update`/`setup` erneut ausführen.

## Troubleshooting (erlebt)

- Profil-Mismatch ("upgraded by a newer Chromium"): `betterwright close --all`, `mv ~/.betterwright/browser/profile{,.stale}`, neu starten.
- Modell-404: ID braucht Tilde-Präfix; gültige IDs via `betterwright models --base-url …`.
- `betterwright doctor` = Backend-Status. Session idle ~15 min; `betterwright close --all` beendet alles.
