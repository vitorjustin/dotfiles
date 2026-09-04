# Global coding standards

These apply in every project, every language, under every agent tool, whether
or not the repo documents them. A repo that says nothing about them has not
opted out — read them as if written into that repo's own standards file.

**Tests** and **Git & Commits** are standards: treat a breach as a documented
violation, not a judgement call, and cite it by name in review.
**Shell & Search** and **Review Guardrails** are operating rules: follow them
while working, but they describe how an agent behaves, not what a diff must
satisfy — don't cite them as review findings.

## Tests

- **Tautological tests considered harmful**: a test that can't fail proves
  nothing. This includes a test that asserts a mock's own stubbed return
  value, re-implements the logic under test instead of exercising it, or
  checks that a framework/library does what the framework already
  guarantees. Cite it as this standard when a test only restates its setup.

## Git & Commits

- **Pre-commit inspection**: before staging or committing, run `git summary`
  (a `~/.gitconfig` alias: `git status --short`, then `git diff --stat HEAD`
  — or `--cached` before the first commit — so staged and unstaged changes
  both show). If the alias isn't set up on this machine, run that sequence
  directly. It's inventory, not review — still read the actual patch
  (`git diff` / `git diff --cached`) before writing the commit message.
- **Commit only your changes**: never stage unrelated, untracked, or
  temporary files (`.scratch/`, `/tmp/`, cross-repo docs).
- **Commit message style and language**: don't infer from the repository
  name. If the repository has commits, read `git log -8 --pretty=%s` and
  match that history's style and language (pt-BR or English) — it is the
  authority, even against your default. Weight recent commits: a mixed
  sample (some `feat:`/`fix:` prefixes, some bare sentence case) means the
  repo is mid-migration, so follow the newest convention, not the majority.
  Ignore trailing `(#123)` PR-number suffixes (squash-merge artifacts) —
  never invent one.
- **Atomic commits**: group related changes into distinct commits rather
  than one monolithic commit.

## Shell & Search

- **Literal search first (ripgrep)**: prefer `rg -F` / `rg --fixed-strings`
  for class names, PHP namespaces (`App\Services\...`), or any string with
  backslashes — otherwise the regex engine reads `\P`, `\S`, `\d` as regex
  escapes. If a regex is unavoidable over such content, a literal backslash
  under single quotes is `\\` (`rg 'App\\Services\\User'`) — do not double
  it to `\\\\`, which silently matches zero results instead of erroring.
  Prefer `-g` glob flags over path regexes for filtering by path.
- **Read files in whole useful units**: prefer one large read over several
  chunked ones — each extra chunked-read turn re-sends the whole
  conversation, so repeated 200-line `sed -n` windows cost more than one
  larger read. Read a file whole when it is under ~2000 lines *and* under
  ~100 KB; check with `wc -lc` when unsure. Both bounds matter: minified
  and bundled output can be two lines and several megabytes, so a line
  count alone will wave it through. Never whole-read lockfiles
  (`composer.lock`, `yarn.lock`, `package-lock.json`), generated or vendor
  files, or minified/bundled output at any size. Target those, and anything
  past the bounds, with `rg -n -C 10 <pattern>` and read only the matched
  range.
- **Symlinks in home directory**: don't write directly to symlinks in home
  directories (e.g. `~/.zshrc`, `~/.agents/AGENTS.md`); resolve and edit the
  underlying source file in `~/dotfiles`.

## Review Guardrails

- **Review mode is strictly READ-ONLY**: when assigned a review, audit, or
  incident inspection (e.g. server downtime), never edit files, stage
  commits, or run mutating commands unless explicitly instructed.
- **No external CodeRabbit CLI**: never invoke the `coderabbit` CLI or other
  external CodeRabbit tooling for code review. Perform reviews directly via
  codebase inspection and agent analysis.
