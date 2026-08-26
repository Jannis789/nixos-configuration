---
name: betterwright-driver
description: Browser tasks via betterwright view + run (Live View, user watches/steers, NO sub-agent). exec only on explicit request. Always read for browser tasks (login, forms, bookings, purchases, reading pages) or when the user mentions "Browser", "Live View", "Chat", "Handoff" or "betterwright". The user is German — reply in German.
---

# BetterWright — Browser

## On skill load: start the browser (one-shot, idempotent)

`run`/`view` need no API key. On skill load, immediately:

```bash
nohup betterwright view --host 127.0.0.1 > /tmp/bw-view.log 2>&1 &
sleep 3 && grep -o 'http://127.0.0.1:[0-9]*/?t=[A-Za-z0-9_-]*' /tmp/bw-view.log
```

- Already running (`betterwright sessions` → `default`)? Give the URL from the log, start nothing new.
- Give the user the URL verbatim (capability token — treat like a password).
- **This is NOT a task.** Then stop and wait for the actual task — no interpreting, no repo inspection, no commits.

## Steer: betterwright run (one tool call per step)

```bash
betterwright run -c "await page.goto('https://example.com'); return page.title()"
# → {ok:true, result:"Example Domain", session:"default"}
```

- Snippet globals: `page`, `snapshot`, `screenshot`, `credentials`, `human`, `controls`, `webagents`, `webmcp`.
- Quoting: shell expands `$` inside double quotes. If the snippet contains `$`, backticks, or nested quotes, write it to a temp file and run `betterwright run - < file` — or use single quotes around `-c`.
- Session `default` persists — same tabs as the viewer, follow-up runs continue.
- Combine action + observation per snippet; when state is unsure, read first (`snapshot`/`innerText`), then act.
- NO `exec`/sub-agent unless explicitly requested. exec needs an API key: `--api-key-env` from secrets.nix, never inline.
- Never put secrets in the command. `vault show --reveal`/`copy`/`rm` forbidden, `vault list` ok.
- Before login/signup/checkout: `betterwright skills show credential-manager`; before GitHub work: `github`.
- 5xx/timeout: retry with 30–60 s backoff before calling a page "down".
