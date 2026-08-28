#!/usr/bin/env bash
# Link the git-tracked global agent standards into every agent tool's
# auto-loaded instruction file. Idempotent: safe to re-run.
#
#   ~/dotfiles/agents/AGENTS.md   <- source of truth (tracked)
#   ~/.agents/AGENTS.md           <- stable indirection point
#   per-tool files                <- symlinks to ~/.agents/AGENTS.md
#
# If dotfiles ever moves, only the ~/.agents link needs fixing.

set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
SRC="$DOTFILES/agents/AGENTS.md"
HUB="$HOME/.agents/AGENTS.md"

[ -f "$SRC" ] || { echo "missing source: $SRC" >&2; exit 1; }

link() {
  local target="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ]; then
    [ "$(readlink -f "$dest")" = "$(readlink -f "$target")" ] && { echo "ok    $dest"; return; }
    rm "$dest"
  elif [ -e "$dest" ]; then
    if [ -s "$dest" ]; then
      mv "$dest" "$dest.bak.$(date +%Y%m%d%H%M%S)"
      echo "bak   $dest -> $dest.bak.*"
    else
      rm "$dest"
    fi
  fi
  ln -s "$target" "$dest"
  echo "link  $dest -> $target"
}

link "$SRC" "$HUB"

# Claude Code: user memory, auto-loaded in every project. Kept as its own
# file so Claude-specific memory can live alongside the @-import.
link "$DOTFILES/agents/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

# Tools that auto-load a single global instruction file.
link "$HUB" "$HOME/.codex/AGENTS.md"
link "$HUB" "$HOME/.gemini/GEMINI.md"
link "$HUB" "$HOME/.config/amp/AGENTS.md"

# OpenCode: native `instructions` array, no symlink needed.
OC="$HOME/.config/opencode/opencode.json"
if [ -f "$OC" ] && command -v jq >/dev/null; then
  if jq -e --arg p "$HUB" '.instructions // [] | index($p)' "$OC" >/dev/null; then
    echo "ok    $OC"
  else
    tmp=$(mktemp)
    jq --arg p "$HUB" '.instructions = ((.instructions // []) + [$p] | unique_by(.))' "$OC" > "$tmp"
    mv "$tmp" "$OC"
    echo "patch $OC (instructions += $HUB)"
  fi
fi

echo
echo "Not covered (no global instruction file): Cursor CLI reads AGENTS.md from"
echo "the working tree only; Cursor IDE user rules live in its settings UI."
