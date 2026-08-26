---
name: betterwright-driver
description: Browser-Aufgaben VORZUGSWEISE via betterwright view (Live View, User schaut zu/lenkt) + betterwright run (direkte Playwright-Snippets, KEIN Sub-Agent). exec (eingebauter Agent-Loop) NUR auf expliziten Wunsch. Immer lesen, wenn eine Browser-Aufgabe ansteht (Login, Formulare, Buchungen, Käufe, Webseiten lesen) oder der User "Browser", "Live View", "Chat", "Handoff" oder "betterwright" erwähnt. Enthält festen Code (genau die Befehle, die auf dieser Maschine verifiziert laufen) und feste Instruktion.
---

# BetterWright — Browser in einem Tool-Call

**Standard: betterwright view + run — kein Sub-Agent, kein exec.**
Der User schaut im Live View zu und lenkt; die KI steuert den Browser
direkt über `betterwright run -c "<snippet>"` (ein Tool-Call pro
Snippet, Ergebnis = JSON). `exec` startet einen eigenen Agent-Loop
(Sub-Agent) und nur auf ausdrücklichen Wunsch des Users verwenden.

## Fester Code (auf dieser Maschine verifiziert)

`betterwright` liegt über den home-manager-Wrapper im PATH
(common/module/home/pi.nix). **`run` und `view` brauchen KEINEN
API-Key** — nur `exec` (Sub-Agent) braucht einen, dann ausschließlich
via `--api-key-env` (kommt aus `secrets.nix`), nie als CLI-Wert.

```bash
# Browser-Aufgabe: Live View starten + Seite per run-Snippet steuern
nohup betterwright view --host 127.0.0.1 > /tmp/bw-view.log 2>&1 &
# → URL aus /tmp/bw-view.log ("Live view: http://…") DEM USER VERBATIM GEBEN

betterwright run -c "await page.goto('https://example.com'); return page.title()"
# → ein JSON-Objekt: {ok:true, result:…, session:"default"}
```

**Verifizierte Fakten (getestet 2026-08-26):**
- `betterwright run` führt ein async-Playwright-Snippet im persistenten
  Browser aus (`default`-Session, gleiche Tabs wie der Viewer) und
  liefert ein JSON-Objekt mit `result`. Globals im Snippet: `page`,
  `snapshot`, `screenshot`, `credentials`, `human`, `controls`,
  `webagents`, `webmcp`.
- `betterwright view` attacht an die laufende Session — der User sieht
  exakt die Tabs, die `run` steuert. Die gedruckte URL ist ein
  Capability-Token (wie ein Passwort behandeln).
- Session "default" persistiert: Folge-`run`s fahren mit dem offenen
  Browser fort.
- exec-Fakten (nur relevant, wenn der User explizit exec will):
  Modell-Backend Nous-Inference, IDs mit `~`-Präfix
  (`~deepseek/deepseek-v4-flash-latest`; Liste: `betterwright models
  --base-url https://inference-api.nousresearch.com/v1` mit gesetztem
  `NOUS_API_KEY`). Ohne Tilde → 404.

## Live View (Standard — immer zuerst starten!)

`betterwright view --host 127.0.0.1` startet den Viewer auf Loopback und
druckt die URL. **Dem User die URL VERBATIM geben** — das ist der Link
zum Zuschauen und zum direkten Eingreifen (Takeover-Controls: er kann
selbst klicken/tippen). **Achtung: Der Chat im Viewer ist OHNE `exec`
nicht funktional** — Nachrichten landen im Puffer, aber nur der
Agent-Loop (`exec`) liest und beantwortet sie. Lenkung des Users läuft
deshalb über den pi-Session-Chat (hier), nicht über den View-Chat. Nie
behaupten, ein Viewer liefe, ohne die URL.

```bash
nohup betterwright view --host 127.0.0.1 > /tmp/bw-view.log 2>&1 &
sleep 3 && grep -o 'http://127.0.0.1:[0-9]*/?t=[A-Za-z0-9_-]*' /tmp/bw-view.log
# → http://127.0.0.1:PORT/?t=<token> — dem User geben!
```

Der User erreicht die URL über seinen SSH-/WireGuard-Tunnel:
`ssh -L PORT:127.0.0.1:PORT jannis` und dann lokal öffnen. Fürs VPS von
unterwegs alternativ `--expose tailscale`. Der Viewer läuft im
Hintergrund weiter, bis `betterwright close --all` oder die Session idle
wird (~15 min).

**Wichtig:** `view` attacht an die `default`-Session — der User sieht in
Echtzeit, was `betterwright run` macht. Kein `--live-view`-Flag bei
`run` nötig.

## Verbindliche Regeln für die KI (fester Ablauf)

1. **Immer `betterwright view` zuerst.** Browser-Aufgabe → View-Daemon
   starten (siehe oben), URL dem User geben. Dann den Browser mit
   `betterwright run -c "<snippet>"` steuern — ein Tool-Call pro Schritt,
   Ergebnis-JSON lesen, `result` an den User geben. KEIN `exec`, KEIN
   Sub-Agent, außer der User verlangt es ausdrücklich.
2. **Lenkung über den pi-Session-Chat, nicht den View-Chat.** Der
   View-Chat ist ohne `exec` funktionslos (siehe oben). User-Nachrichten
   hier als nächsten `run`-Schritt umsetzen (Session merkt sich den
   Kontext).
3. **Ein Aktion+Beobachtung pro `run`-Call.** Aktion (klicken, tippen,
   navigieren) und Beobachtung (Text, URL, Screenshot) in einem Snippet
   kombinieren. Bei unsicherem Zustand zuerst lesen (`innerText`,
   `snapshot`), dann handeln. `human.*`, `credentials.*`, `captcha.*`
   stehen als Globals im Snippet zur Verfügung.
4. **ask/handoff nur bei `exec` relevant.** Fragt der Agent-Loop per
   `ask` den User (folgenreiche Aktionen), gibt's die Antwort über den
   Chat/Viewer. `handoff` = MFA/CAPTCHA/User-Schritt; nach Done weiter.
5. **Secrets.** Key nur via `--api-key-env`/`export`, nie im Kommando.
   `vault show --reveal`/`vault copy`/`vault rm` sind verboten.
   `vault list` (Metadaten) erlaubt.
6. **Skill-Packs.** Vor Login/Signup/Checkout das
   `credential-manager`-Pack lesen (`betterwright skills show
   credential-manager`), vor GitHub-Arbeit `github`.
7. **Transiente Fehler retrybar.** 5xx/Timeout: mit Backoff 30–60 s erneut
   versuchen, bevor eine Seite als down gilt. `reason` im Ergebnis lesen:
   `timeout`, `no_progress`, `interrupted` usw. erklären das Ende.

## Browser auf NixOS (wichtig!)

Der mitgelieferte BetterChromium-Fork ist ein generisches Linux-Binary und
läuft auf NixOS NICHT (Stub-LD: "NixOS cannot run dynamically linked
executables"). Fix hier bereits angewendet: `betterchromium` ist ein
Symlink auf das nixpkgs-Chromium:

```bash
ls -la ~/.betterwright/chromium/linux-x64/betterchromium
# → … -> /nix/store/…-chromium-150.0.7871.181/bin/chromium
```

Nach einem `betterwright update`/`setup` (lädt den Fork neu) den Symlink
erneut setzen:

```bash
B=~/.betterwright/chromium/linux-x64/betterchromium
mv "$B" "$B.nixos-dead" 2>/dev/null
ln -s /nix/store/5prcsr1v91xai06jmpxxh3wh4c79h0s6-chromium-150.0.7871.181/bin/chromium "$B"
```

`BETTERWRIGHT_CHROMIUM_PATH` und `--browser` werden von run/exec
ignoriert — nur der Symlink-Ersatz funktioniert.

## Troubleshooting (auf dieser Maschine erlebt)

- **"profile … upgraded by a newer Chromium"**: Backend-Wechsel-Mismatch
  (Chromium-Fork 150.x vs. CloakBrowser 146.x). Fix: Daemons stoppen
  (`betterwright close --all`), Profil beiseite legen
  (`mv ~/.betterwright/browser/profile{,.stale}`), neu starten. Vault
  überlebt. — Hier bereits erledigt (`profile.stale-150` existiert).
- **Modell-404 "not found … OpenRouter catalog"**: ID falsch/prefixed falsch
  → `betterwright models --base-url …` für gültige IDs.
- **`betterwright doctor`** zeigt Backend + Probleme.
- Session idle ~15 min → Seiten schließen; `betterwright close --all` beendet
  alles. `betterwright sessions` zeigt den Daemon-Zustand.
