#!/usr/bin/env bash
# Read-only disk inventory for cleanup decisions.
# NEVER deletes. See docs/disk-cleanup.md
set -euo pipefail

hr() { printf '%s\n' "----------------------------------------"; }
exists() { [[ -e "$1" ]]; }

size_of() {
  local p=$1
  if exists "$p"; then du -sh "$p" 2>/dev/null | cut -f1; else echo "—"; fi
}

section() { printf '\n### %s\n' "$1"; }

echo "=== disk inventory (read-only) ==="
echo "host: $(hostname)  date: $(date -Iseconds)"
echo "home: $HOME"
df -h /dev/sdd 2>/dev/null || df -h "$HOME" | tail -1

section "watched paths"
paths=(
  "$HOME/.local/share/zed/external_agents"
  "$HOME/.local/share/zed/node/cache"
  "$HOME/.gemini/antigravity/browser_recordings"
  "$HOME/.local/share/opencode/opencode.db"
  "$HOME/.local/share/claude/versions"
  "$HOME/.asdf/installs/nodejs"
  "$HOME/.vscode-server/extensions"
  "$HOME/.vscode-server/data/CachedExtensionVSIXs"
  "$HOME/.cargo/registry/src"
  "$HOME/.cargo/registry/cache"
  "$HOME/.hermes"
)
for p in "${paths[@]}"; do
  printf '%8s  %s\n' "$(size_of "$p")" "$p"
done | sort -hr

section "zed external_agents builds"
if exists "$HOME/.local/share/zed/external_agents/registry"; then
  du -sh "$HOME"/.local/share/zed/external_agents/registry/*/* 2>/dev/null | sort -hr || true
else
  echo "(missing)"
fi

section "claude versions (current via symlink)"
if command -v claude >/dev/null 2>&1; then
  cur=$(readlink -f "$(command -v claude)" || true)
  echo "symlink: $(command -v claude) -> $cur"
  echo "current: $(basename "$cur")"
fi
if exists "$HOME/.local/share/claude/versions"; then
  du -sh "$HOME"/.local/share/claude/versions/* 2>/dev/null | sort -hr || true
fi

section "asdf nodejs"
if command -v asdf >/dev/null 2>&1; then
  asdf current nodejs 2>/dev/null || true
  asdf list nodejs 2>/dev/null || true
fi
if exists "$HOME/.asdf/installs/nodejs"; then
  du -sh "$HOME"/.asdf/installs/nodejs/* 2>/dev/null | sort -hr || true
  echo "--- global npm modules (top) ---"
  for d in "$HOME"/.asdf/installs/nodejs/*; do
    [[ -d "$d" ]] || continue
    echo "· $(basename "$d")"
    du -sh "$d"/lib/node_modules/* 2>/dev/null | sort -hr | head -5 || true
  done
fi
echo "--- .tool-versions nodejs pins (home + sites) ---"
if command -v rg >/dev/null 2>&1; then
  rg -n '^nodejs' "$HOME/.tool-versions" "$HOME/sites" --glob '**/.tool-versions' 2>/dev/null || true
else
  grep -Rnh '^nodejs' "$HOME/.tool-versions" "$HOME/sites" --include='.tool-versions' 2>/dev/null || true
fi

section "vscode-server chatgpt / claude-code"
ext="$HOME/.vscode-server/extensions"
vsix="$HOME/.vscode-server/data/CachedExtensionVSIXs"
if [[ -f "$ext/extensions.json" ]]; then
  python3 - <<'PY' 2>/dev/null || true
import json, pathlib
p = pathlib.Path.home()/".vscode-server/extensions/extensions.json"
try:
    data = json.loads(p.read_text())
except Exception as e:
    print("parse error", e); raise SystemExit
for e in data:
    i = e.get("identifier",{}).get("id","")
    if "chatgpt" in i or "claude-code" in i:
        print("ACTIVE", i, e.get("version"), e.get("relativeLocation"))
PY
fi
du -sh "$ext"/openai.chatgpt-* "$ext"/anthropic.claude-code-* 2>/dev/null | sort -hr || true
echo "--- VSIX ---"
du -sh "$vsix"/openai.chatgpt-* "$vsix"/anthropic.claude-code-* 2>/dev/null | sort -hr || true

section "opencode.db (sqlite stats if sqlite3 present)"
db="$HOME/.local/share/opencode/opencode.db"
if exists "$db"; then
  ls -lah "$db"* 2>/dev/null || true
  if command -v sqlite3 >/dev/null 2>&1; then
    sqlite3 "$db" 'PRAGMA page_count; PRAGMA freelist_count; PRAGMA page_size;' 2>/dev/null \
      | paste - - - | awk '{printf "pages=%s freelist=%s page_size=%s\napprox_reclaim_MiB=%.0f\n",$1,$2,$3,($2*$3)/1024/1024}'
  fi
fi

section "hermes"
if exists "$HOME/.hermes"; then
  ls -la "$HOME/.local/bin/hermes" 2>/dev/null || echo "no ~/.local/bin/hermes"
  du -sh "$HOME/.hermes"/* 2>/dev/null | sort -hr | head -10 || true
fi

section "cargo registry"
du -sh "$HOME"/.cargo/registry/* 2>/dev/null | sort -hr || true

echo
hr
echo "guide: ~/dotfiles/docs/disk-cleanup.md"
echo "no deletions performed."
