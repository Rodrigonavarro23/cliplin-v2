---
name: project-init
description: >-
  Initializes the current repo to use Cliplin v2 by default: writes or merges
  AGENTS.md (the canonical, host-neutral briefing), wires Claude Code to it
  (CLAUDE.md import, .claude/agents/cliplin.md as default main-thread agent via
  .claude/settings.json), and scaffolds docs/ and .cliplin/. Idempotent — never
  overwrites existing instructions.
when_to_use: >-
  Use when the human asks to initialize, set up, adopt or "turn on" Cliplin in a
  repo (e.g. "init cliplin", "inicializa el repo con cliplin"), typically right
  after a global or marketplace install. Do NOT use to write specs — that's
  cycle-init (new behavior) or reverse-engineer (existing code).
---

# Skill: project-init

Implements `docs/tdrs/project-briefing.md` and `docs/tdrs/main-thread-agent.md` from
inside the host, so a globally installed plugin can adopt a project without re-running
any installer script.

Templates live in the plugin's `templates/` directory — two levels up from this
skill's base directory (`<skill-dir>/../../templates/`). Read them from there; never
invent their content.

Target = the current working directory's repo root (`git rev-parse --show-toplevel`
if it is a git repo, otherwise the cwd). Confirm the target path with the human in
one line before writing if it is not obviously the project they meant.

## Step 1: Survey (read-only)

Check and remember which of these already exist in the target:

- `AGENTS.md`, `CLAUDE.md`, `.claude/CLAUDE.md`
- `.claude/agents/cliplin.md`, `.claude/settings.json`
- `docs/features/`, `docs/tdrs/`, `docs/adrs/`, `docs/business/`, `.cliplin/`
- `.gitmodules` with at least one submodule (coordinator repo)
- Source code present (anything beyond docs/config) — decides the Step 6 suggestion

Detect the host: running in Claude Code → do Steps 2–5. Running in Codex (or another
host that reads `AGENTS.md` natively) → do Steps 2 and 5 only; skip 3 and 4.

## Step 2: AGENTS.md (canonical briefing)

Source: `templates/agents-md.template.md`.

- Absent → write it as-is.
- Present with a line exactly `## Cliplin v2` → leave it untouched, report "already
  initialized".
- Present without it → append a blank line and the template to the end. Never
  rewrite or reorder the existing content.

## Step 3: CLAUDE.md → AGENTS.md (Claude Code only)

Claude Code reads `CLAUDE.md`, not `AGENTS.md`. Make it import `AGENTS.md` so there is
one source of truth:

- Neither `CLAUDE.md` nor `.claude/CLAUDE.md` exists → write root `CLAUDE.md`
  containing exactly:
  ```
  @AGENTS.md
  ```
- Root `CLAUDE.md` exists → if it has no line `@AGENTS.md`, append one (preceded by a
  blank line). Leave everything else as-is.
- Only `.claude/CLAUDE.md` exists → same rule there, but the import line is
  `@../AGENTS.md` (imports resolve relative to the importing file).
- If an existing CLAUDE.md already contains a `## Cliplin v2` section (written by the
  older `install-claude.sh <path>`), keep it and still add the import — tell the human
  the old section can be deleted since `AGENTS.md` now carries the briefing.

## Step 4: Default main-thread agent (Claude Code only)

Per `docs/tdrs/main-thread-agent.md` — project scope, never plugin scope:

1. `.claude/agents/cliplin.md`: absent → write it from
   `templates/cliplin-agent.template.md`. Present → leave it, report it was kept.
2. `.claude/settings.json` (tracked team settings — NOT `settings.local.json`):
   - Absent → write `{"agent": "cliplin"}` (pretty-printed JSON).
   - Present → parse it, set top-level `"agent": "cliplin"` preserving every other key.
     If `agent` already holds a different value, do NOT overwrite it: ask the human
     first.
   - Validate the result is valid JSON before finishing.

## Step 5: Scaffold

Create only what is missing (never touch existing files):

- `docs/features/`, `docs/tdrs/`, `docs/adrs/`, `docs/business/` — each with an empty
  `.gitkeep` so git tracks it.
- `.cliplin/` — empty directory with `.gitkeep`. Do NOT create
  `.cliplin/context-summary.yaml` here; `context-summary-sync` creates it from its
  template on the first cycle close or `reverse-engineer` run.

## Step 6: Report and next step

Report a short list of each path with `created`, `appended` or `kept`. Then:

- Claude Code: tell the human to restart the session (or open a new one) so the
  `cliplin` agent and `CLAUDE.md` load.
- Repo has source code and no `.feature` files → suggest `reverse-engineer` to
  bootstrap baseline specs. Suggest only; do not run it.
- Otherwise → suggest describing the first feature, which will route to `cycle-init`.
- `.gitmodules` has submodules → mention it will act as a coordinator automatically.

## Constraints (MUST follow)

- Idempotent: running it twice produces no diff the second time.
- Never overwrite or delete existing human content; only create or append.
- Write no specs (ADRs/TDRs/features) — that's `cycle-init` / `reverse-engineer`.
- Do not commit. Leave the changes in the working tree for the human to review.
