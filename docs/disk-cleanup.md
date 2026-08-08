# Disk cleanup guide

Personal cache/tool cleanup for this machine. **Human runs all deletions.** AI/agents must only inventory and advise — never `rm`, `unlink`, `shred`, `truncate`, `VACUUM` into live DBs, `asdf uninstall`, `npm uninstall -g`, or `cargo cache` clean.

Companion (read-only): `bin/disk-inventory.sh`

---

## How this guide is organized

| Section | Meaning |
|---|---|
| **0. Rules** | Hard constraints before any command |
| **1. Inventory** | Always run first; sizes + “what is current” |
| **2. Zero-risk** | Pure caches; app/tool recreates; no settings/history loss |
| **3. Safe (rebuildable)** | Deleted bits re-download on next launch/build; brief slowdown OK |
| **4. Human decision** | Weigh before delete; may drop history, pins, or unused apps |
| **5. Older-version pattern** | Detect current → list others → delete only non-current |
| **6. Per-target playbooks** | Exact paths + commands for each known hog |
| **7. Aftercare** | Verify nothing broke |

Risk tags used below: `ZERO` · `SAFE` · `DECIDE`

---

## 0. Rules

1. **Inventory before delete.** Never delete blind.
2. **Quit the owning app** (Zed, VS Code server, opencode, Claude, cargo builds) before touching its files.
3. **Prefer keep-newest** over wipe-all when multiple versions exist.
4. **Never delete** active symlink targets, `.tool-versions` pins you still need, or live DBs without backup.
5. **AI block:** no deletion/mutation cleanup commands. Print commands for the human only.
6. Re-run inventory after each batch; free space is the feedback loop.

---

## 1. Inventory (always first)

```bash
# full report (read-only)
~/dotfiles/bin/disk-inventory.sh

# or one-shot sizes
du -sh \
  ~/.local/share/zed/external_agents \
  ~/.local/share/zed/node/cache \
  ~/.gemini/antigravity/browser_recordings \
  ~/.local/share/opencode/opencode.db \
  ~/.local/share/claude/versions \
  ~/.asdf/installs/nodejs \
  ~/.vscode-server/extensions \
  ~/.vscode-server/data/CachedExtensionVSIXs \
  ~/.cargo/registry/src \
  ~/.hermes \
  2>/dev/null | sort -hr
```

### Detect “current” version (generic patterns)

Use these **before** crafting any “delete older” command.

```bash
# symlink-based CLI (claude, hermes, …)
readlink -f "$(command -v claude)"
basename "$(readlink -f "$(command -v claude)")"

# asdf
asdf current nodejs
asdf list nodejs
# project pins (do not remove a version still pinned)
rg -n '^nodejs' ~/.tool-versions ~/sites --glob '**/.tool-versions'

# vscode-server extensions (active = extensions.json)
python3 - <<'PY'
import json, pathlib
p = pathlib.Path.home()/".vscode-server/extensions/extensions.json"
for e in json.loads(p.read_text()):
    i = e.get("identifier",{}).get("id","")
    if i in ("openai.chatgpt","anthropic.claude-code") or "chatgpt" in i or "claude-code" in i:
        print(i, e.get("version"), e.get("relativeLocation"))
PY

# zed external agents: newest mtime / largest set — list and keep latest per agent name
ls -lt ~/.local/share/zed/external_agents/registry/* 2>/dev/null
du -sh ~/.local/share/zed/external_agents/registry/*/* 2>/dev/null | sort -hr
```

---

## 2. Zero-risk (`ZERO`)

No settings, no project state, no auth. Worst case: next run is slightly slower while cache refills.

| Target | Why zero-risk |
|---|---|
| `~/.local/share/zed/node/cache` | npm `_cacache` for Zed’s node |
| `~/.vscode-server/data/CachedExtensionVSIXs/` | VSIX download cache only |
| `~/.cargo/registry/src` | unpacked crate sources (`.crate` cache can stay) |

### Commands

```bash
# Zed node npm cache
du -sh ~/.local/share/zed/node/cache
rm -rf ~/.local/share/zed/node/cache   # HUMAN

# VS Code Server VSIX cache (all)
du -sh ~/.vscode-server/data/CachedExtensionVSIXs
rm -rf ~/.vscode-server/data/CachedExtensionVSIXs/*   # HUMAN

# Cargo unpacked sources only (keeps ~/.cargo/registry/cache)
du -sh ~/.cargo/registry/src
rm -rf ~/.cargo/registry/src   # HUMAN
```

---

## 3. Safe / rebuildable (`SAFE`)

App re-fetches on next use. May lose **optional** local artifacts (old agent builds, browser recordings), not core config.

| Target | Rebuild trigger | Note |
|---|---|---|
| Zed `external_agents` old `v_*` | Open Zed agent again | Prefer drop old builds, keep newest |
| Gemini Antigravity `browser_recordings` | New recording sessions | Old sessions gone forever |
| Cargo full registry wipe | Next `cargo build` | Slower first builds |
| VS Code old extension **folders** (non-active) | Reinstall/update ext | Keep active from `extensions.json` |
| Claude old binaries in `versions/` | N/A (updates add new) | Keep symlink target only |

### Commands

```bash
# --- Zed external agents: list then drop OLD builds only ---
du -sh ~/.local/share/zed/external_agents/registry/*/*
# Inspect; delete specific old dirs, e.g.:
# rm -rf ~/.local/share/zed/external_agents/registry/opencode/v_OLDHASH   # HUMAN
# Nuclear (full re-download):
# rm -rf ~/.local/share/zed/external_agents   # HUMAN

# --- Gemini browser recordings ---
du -sh ~/.gemini/antigravity/browser_recordings/*
rm -rf ~/.gemini/antigravity/browser_recordings/*   # HUMAN

# --- Claude Code: keep only current ---
CUR=$(basename "$(readlink -f "$(command -v claude)")")
echo "KEEP: $CUR"
ls -1 ~/.local/share/claude/versions
# delete each non-current explicitly, e.g.:
# rm -f ~/.local/share/claude/versions/2.1.222   # HUMAN
# verify
ls -l ~/.local/bin/claude && claude --version
```

---

## 4. Human decision (`DECIDE`)

Weigh cost vs benefit. Snapshot/backup first when unsure.

| Target | Weigh | Risk if wrong |
|---|---|---|
| `opencode.db` | Disk vs chat/history retention | History loss if deleted; VACUUM only shrinks free pages |
| asdf `nodejs` versions | Every ver pinned by some `~/sites/**/.tool-versions`? | Breaks project toolchains |
| asdf global npm pkgs | Still using `@opencode-ai`, `@openai`, CLIs? | Missing global bins until reinstall |
| vscode active ext dir | Only remove **non-active** versions | Broken remote ext host |
| `~/.hermes` | App abandoned? Need `.env`/`auth.json`? | Secrets + install gone |
| Cargo `registry/cache` | Want max space vs offline builds | Redownload all crates |

### Decision checklist

```text
[ ] Is a project .tool-versions / lockfile pinning this?
[ ] Is a symlink in ~/.local/bin pointing at it?
[ ] Is the app running right now?
[ ] Does it hold secrets (auth.json, .env, *.db)?
[ ] Can I reinstall in <5 minutes if needed?
[ ] Did I back up if irreversible (DB, recordings, hermes auth)?
```

---

## 5. Older-version pattern (reusable)

```bash
# 1) resolve CURRENT
CURRENT=…   # from section 1

# 2) list installed + sizes
ls -1 "$DIR"
du -sh "$DIR"/* | sort -hr

# 3) show candidates (everything except current)
for v in "$DIR"/*; do
  [[ "$(basename "$v")" == "$CURRENT" ]] && continue
  du -sh "$v"
done

# 4) HUMAN deletes explicit paths only (no globs that include CURRENT)
# rm -rf "$DIR/$OLD_VERSION"
```

**Never** `rm -rf "$DIR"/*` when a live symlink points inside `$DIR`.

---

## 6. Per-target playbooks

### 6.1 Zed — `~/.local/share/zed/node/cache` · `ZERO` · ~hundreds MB

```bash
du -sh ~/.local/share/zed/node/cache
rm -rf ~/.local/share/zed/node/cache   # HUMAN
```

### 6.2 Zed — `~/.local/share/zed/external_agents` · `SAFE` · ~1G

Cached ACP agents (opencode, codex-acp, …), multiple `v_*` builds.

```bash
du -sh ~/.local/share/zed/external_agents/registry/*/*
# keep newest per agent name; remove older v_* dirs   # HUMAN
# or full reset:
# rm -rf ~/.local/share/zed/external_agents   # HUMAN
```

### 6.3 Gemini Antigravity recordings · `SAFE` · often multi-GB

```bash
du -sh ~/.gemini/antigravity/browser_recordings/*
rm -rf ~/.gemini/antigravity/browser_recordings/*   # HUMAN
```

Irreversible for those session captures. Config elsewhere untouched.

### 6.4 opencode DB — `~/.local/share/opencode/opencode.db` · `DECIDE`

SQLite. **Do not delete** unless you accept full history loss.

```bash
# quit opencode first
ls -lah ~/.local/share/opencode/opencode.db*
sqlite3 ~/.local/share/opencode/opencode.db 'PRAGMA page_count; PRAGMA freelist_count; PRAGMA page_size;'

# backup then shrink free pages only
cp -a ~/.local/share/opencode/opencode.db ~/opencode.db.bak-$(date +%F)   # HUMAN
sqlite3 ~/.local/share/opencode/opencode.db 'VACUUM;'   # HUMAN — modest reclaim

# optional offline compress of backup (not the live DB)
# gzip -k ~/opencode.db.bak-$(date +%F)   # HUMAN
```

Also review (separate decision): `~/.local/share/opencode/{snapshot,storage,tool-output,log}`.

### 6.5 Claude Code versions — `~/.local/share/claude/versions` · `SAFE`

```bash
CUR=$(basename "$(readlink -f "$(command -v claude)")")
echo "current=$CUR"
du -sh ~/.local/share/claude/versions/*
# rm -f ~/.local/share/claude/versions/<OLD>   # HUMAN, each OLD != $CUR
claude --version
```

### 6.6 asdf nodejs — `~/.asdf/installs/nodejs` · `DECIDE`

```bash
# sizes
du -sh ~/.asdf/installs/nodejs/* | sort -hr

# global npm bulk (often the real hog)
for d in ~/.asdf/installs/nodejs/*; do
  echo "=== $(basename "$d") ==="
  du -sh "$d/lib/node_modules"/* 2>/dev/null | sort -hr | head -8
done

# who pins what
asdf current nodejs
rg -n '^nodejs' ~/.tool-versions ~/sites --glob '**/.tool-versions'

# remove a version ONLY if nothing pins it
# asdf uninstall nodejs <version>   # HUMAN

# fzf multi-select (still HUMAN confirmation mentally)
# asdf list nodejs | sed 's/[* ]//g' | fzf -m --preview 'du -sh ~/.asdf/installs/nodejs/{}' \
#   | while read -r v; do asdf uninstall nodejs "$v"; done   # HUMAN

# prune fat globals on the ACTIVE node (example)
# npm uninstall -g @opencode-ai   # HUMAN — only if unused
```

**Weight:** every listed node version may be required by a repo under `~/sites`. Prefer uninstalling global packages over whole Node versions.

### 6.7 VS Code Server extensions · `SAFE`/`DECIDE`

Paths:
- installed: `~/.vscode-server/extensions/`
- VSIX cache: `~/.vscode-server/data/CachedExtensionVSIXs/` · `ZERO`

```bash
# active chatgpt / claude-code
python3 - <<'PY'
import json, pathlib
p = pathlib.Path.home()/".vscode-server/extensions/extensions.json"
for e in json.loads(p.read_text()):
    i = e.get("identifier",{}).get("id","")
    if "chatgpt" in i or "claude-code" in i:
        print("ACTIVE", i, e.get("version"), e.get("relativeLocation"))
PY

ls -d ~/.vscode-server/extensions/openai.chatgpt-* \
      ~/.vscode-server/extensions/anthropic.claude-code-* 2>/dev/null
du -sh ~/.vscode-server/extensions/openai.chatgpt-* \
       ~/.vscode-server/extensions/anthropic.claude-code-* 2>/dev/null

# close remote VS Code sessions, then remove NON-active dirs + matching VSIX  # HUMAN
# EXT=~/.vscode-server/extensions
# VSIX=~/.vscode-server/data/CachedExtensionVSIXs
# rm -rf "$EXT/openai.chatgpt-<OLD>-linux-x64" \
#        "$EXT/anthropic.claude-code-<OLD>-linux-x64" \
#        "$VSIX/openai.chatgpt-<OLD>-linux-x64" \
#        "$VSIX/anthropic.claude-code-<OLD>-linux-x64"
```

### 6.8 Cargo registry — `~/.cargo/registry/src` · `ZERO` (src) / `SAFE` (cache)

```bash
du -sh ~/.cargo/registry/src ~/.cargo/registry/cache ~/.cargo/git 2>/dev/null

rm -rf ~/.cargo/registry/src     # HUMAN — zero-risk
# rm -rf ~/.cargo/registry/cache # HUMAN — safe, redownload crates
# optional helper:
# cargo install cargo-cache && cargo cache -a   # HUMAN
```

Does **not** remove toolchains or `~/.cargo/bin`.

### 6.9 Hermes full uninstall — `~/.hermes` · `DECIDE`

Last-resort remove of unused agent. Holds `.env` / `auth.json`.

```bash
# inspect
ls -la ~/.local/bin/hermes
readlink -f ~/.local/bin/hermes
du -sh ~/.hermes
# backup secrets if any chance of return
# cp -a ~/.hermes/.env ~/.hermes/auth.json ~/hermes-secrets-bak/   # HUMAN

rm -f ~/.local/bin/hermes    # HUMAN
rm -rf ~/.hermes             # HUMAN

# leftovers check (read-only)
rg -n hermes ~/.bashrc ~/.zshrc ~/.profile 2>/dev/null
ls ~/.config/systemd/user/*hermes* 2>/dev/null
```

---

## 7. Aftercare

```bash
~/dotfiles/bin/disk-inventory.sh
df -h ~
command -v claude; claude --version 2>/dev/null
command -v node; node -v; asdf current nodejs
command -v cargo; cargo --version
# launch Zed / VS Code remote once if you trimmed their caches
```

If something missing: reinstall via normal channel (asdf install, ext marketplace, cargo build, Zed agent install) — that is expected for `SAFE` targets.

---

## Quick matrix

| Path | Tag | Typical action |
|---|---|---|
| `~/.local/share/zed/node/cache` | ZERO | `rm -rf` |
| `~/.vscode-server/data/CachedExtensionVSIXs` | ZERO | wipe files |
| `~/.cargo/registry/src` | ZERO | `rm -rf` |
| `~/.local/share/zed/external_agents` | SAFE | drop old `v_*` |
| `~/.gemini/antigravity/browser_recordings` | SAFE | wipe sessions |
| `~/.local/share/claude/versions` | SAFE | keep current only |
| `~/.vscode-server/extensions/*-OLD` | SAFE | remove non-active |
| `~/.cargo/registry/cache` | SAFE | optional wipe |
| `~/.local/share/opencode/opencode.db` | DECIDE | backup + VACUUM only |
| `~/.asdf/installs/nodejs/*` | DECIDE | uninstall unpinned / prune globals |
| `~/.hermes` | DECIDE | full uninstall if unused |

---

## AI / agent contract

```text
ALLOWED: du, ls, readlink, asdf list/current, sqlite3 PRAGMA (read), cat, rg, df
BLOCKED: rm, rmdir, unlink, shred, truncate, mv of cleanup targets,
         asdf uninstall, npm uninstall, cargo cache clean, VACUUM,
         > redirects that wipe files, find -delete, shred
```

When advising: print the exact command block and stop. Human pastes and runs.
