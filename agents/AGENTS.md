# Global coding standards

These are implicit coding standards: they are always in force, in every
project, in every language, under every agent tool, whether or not the repo
documents them. A repo that says nothing about them has not opted out — read
them as if they were written into that repo's own standards file.

When reviewing code, treat a breach of one of these as a documented standards
violation, not a judgement call, and cite it by name.

## Tests

- Tautological tests considered harmful.

## Git & Commits

- **Pre-commit inspection**: Before staging or committing, run `git summary` to see
  modified/untracked files and the diff stat in a single turn. It reports staged and
  unstaged changes together, so it stays accurate after `git add`.
- **Commit only your changes**: Never stage unrelated, untracked, or temporary files
  (`.scratch/`, `/tmp/`, or cross-repo docs). Inspect `git summary` first.
- **Commit message style and language**: Do not assume from the repository name. Read
  `git log -8 --pretty=%s` and match those commits' styling and language (pt-BR or
  English). The repository's own history is the authority; follow it even when it
  contradicts your default. Weight the most recent commits: if the sample is mixed —
  some `feat:`/`fix:` prefixes, some bare sentence case — the repo is mid-migration, so
  follow the newest convention rather than the majority. Ignore trailing `(#123)` PR
  number suffixes; those come from squash merges, never invent one.
- **Atomic commits**: Group related changes into distinct, atomic commits rather than
  one monolithic commit.

## Shell & Search Standards

- **Literal search first (Ripgrep)**: Always prefer `rg -F` (or `rg --fixed-strings`)
  when searching for class names, PHP namespaces (`App\Services\...`), or file paths
  containing backslashes. This avoids the Rust regex engine reading `\P`, `\S` or `\d`
  as regex escapes.
- **Regex escaping**: If a regex is strictly required over content with backslashes,
  write `\\` for each literal backslash inside single quotes
  (`rg 'App\\Services\\User'`), or use `-g` glob flags instead of path regexes.
  Do not double it again to `\\\\` — under single quotes that matches two literal
  backslashes and silently finds nothing.
- **Read files in whole useful units**: Prefer one large read over several chunked ones.
  Repeated 200-line `sed -n` windows are the expensive pattern: each extra turn re-sends
  the whole conversation, so five 200-line reads cost far more than one 1000-line read.
  Read the entire file when it is reasonably sized; otherwise target it directly with
  `rg -n -C 10 <pattern>` and read the range that matters.
- **Symlinks in home directory**: Do not attempt to write directly to symlinks in home
  directories (e.g., `~/.zshrc`, `~/.agents/AGENTS.md`); resolve and edit the underlying
  source file in `~/dotfiles`.

## Review Guardrails

- **Review mode is strictly READ-ONLY**: When assigned a review, audit, or incident inspection task (e.g., server downtime), NEVER edit files, stage commits, or execute mutating commands unless explicitly instructed.
- **No external CodeRabbit CLI**: Never invoke the `coderabbit` CLI or external CodeRabbit tools for code reviews. Perform all code reviews directly using codebase inspection and agent analysis.
