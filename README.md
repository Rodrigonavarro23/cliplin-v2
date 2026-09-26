# Cliplin v2

**Spec-first AI development, agent-native.** Supports Claude Code and Codex. No framework CLI, binary, or vector database. Coordinates across repos out of the box.

Cliplin v2 is a dual-host plugin made from plain text and shell. It turns Claude Code or Codex into a disciplined spec-first development partner: every feature gets a Gherkin spec with a forced governance trail before a line of code exists, every implementation session closes with a validation report written to disk, and it knows the difference between "this repo works alone" and "this repo coordinates three others" without you ever setting a flag.

## Why this exists

Most spec-first AI tooling stops at one repo and trusts the model to remember the rules. Neither of those is good enough once you're past a single project:

- **Real projects span multiple repos.** A feature that touches an API and its three consumers needs something smarter than "hope the agent figures out which repos matter." Cliplin reads `.gitmodules`, recognizes when it's coordinating instead of working alone, and delegates to scoped sub-agents — verified against real multi-repo open-source projects, not a diagram.
- **"The model should remember to validate" isn't a real guarantee.** Cliplin's `cycle-validate` writes an evidence-backed report to disk — `.cliplin/cycles/<id>.json` — every time, pass or fail, before it tells you anything. You can check whether validation actually ran without re-reading the conversation.
- **Semantic search is the wrong tool for a folder of markdown.** Specs are small, structured, and path-routable. Cliplin finds them with `grep`/`glob`/`read`, orchestrated by the model's own reasoning — no embeddings, no index to keep in sync, no server to run.

## Getting started

The recommended path: install Cliplin **once, globally**, then adopt each project
from inside Claude Code with the `project-init` skill. No per-project installer, no
CLI.

### 1. Install globally (once per machine)

```bash
git clone https://github.com/Rodrigonavarro23/cliplin-v2.git ~/code/cliplin-v2
bash ~/code/cliplin-v2/install-claude.sh --global
```

This copies the plugin to `~/.claude/skills/cliplin-v2/`, so it loads in every
Claude Code session. To update later, `git pull` and run the same command again; it
replaces the installed copy instead of duplicating it.

Restart Claude Code. The session banner reads `CLIPLIN V2 PLUGIN ACTIVE`. In a repo
that hasn't adopted Cliplin yet, the banner ends with a hint to run `project-init`.

### 2. Initialize a project (once per repo)

Open Claude Code in the repo and say:

```
run the project-init skill
```

It writes:

| Path | What it is |
|---|---|
| `AGENTS.md` | The Cliplin briefing and routing rules. Single source of truth, host-neutral (Codex reads it natively). |
| `CLAUDE.md` | One line, `@AGENTS.md`, so Claude Code loads the same briefing. |
| `.claude/agents/cliplin.md` | The `cliplin` agent: classifies every request before acting. |
| `.claude/settings.json` | `"agent": "cliplin"`, which makes that agent the default main thread **for this project only**. |
| `docs/{features,tdrs,adrs,business}/`, `.cliplin/` | Empty scaffold (`.gitkeep`). |

It's safe on repos that already have instructions:
- Existing `AGENTS.md`/`CLAUDE.md` get a section appended, never overwritten.
- Existing `settings.json` keys are preserved; if another `agent` is already set, it asks before changing it.
- Running it twice changes nothing.

Nothing is committed, so review the diff and commit it yourself so your team shares the setup.

**Restart the session** so the `cliplin` agent takes over.

### 3. Seed specs (existing code only)

If the repo already has code but no specs, `project-init` suggests running
`reverse-engineer`. It proposes baseline ADRs, TDRs and `.feature` files from what
the code actually does, and writes only what you approve:

```
run reverse-engineer on this repo
```

Skip this on a brand-new repo.

### 4. Just ask for what you want

```
Add support for rate-limiting the login endpoint.
```

The `cliplin` agent routes it for you:

- **Behavior change, no approved spec yet** → `cycle-init`. It checks whether this is new behavior or an evolution of an existing feature, loads the governing context, and asks at most 3 sharp questions, and only if the request is genuinely ambiguous. Then it drafts a `.feature` with a `@constraints` block naming exactly which decisions govern it. No code yet.
- **Approved spec** → `cycle-run`. It implements up to 3 scenarios per session and closes with `cycle-validate`, which writes an evidence report to `.cliplin/cycles/<id>.json` and updates `.cliplin/context-summary.yaml`.
- **Anything else** (reading, debugging, running tests, cleanup) → proceeds normally.

If the repo has git submodules, it acts as a coordinator automatically: scouts each
child repo, then delegates to a worker where the change actually lands.

## Other install options

The plugin payload under `plugins/cliplin-v2/` is shared by both hosts. Only the
manifest, marketplace and installer are host-specific. Whatever the install path,
adopt each project with `project-init` as above.

**Claude Code marketplace** (alternative to `--global`; pick one, never both, since they share a
plugin name and one silently fails to load):

```bash
claude plugin marketplace add /path/to/cliplin-v2
claude plugin install cliplin-v2@cliplin
# or: bash install-claude.sh --marketplace
```

**Codex:**

```bash
codex plugin marketplace add /path/to/cliplin-v2
codex plugin add cliplin-v2@cliplin
# or: bash install-codex.sh --marketplace
```

In Codex, `project-init` writes only `AGENTS.md` and the scaffold.

**Plugin development** (one session, no install; `/reload-plugins` picks up edits):

```bash
claude --plugin-dir /path/to/cliplin-v2/plugins/cliplin-v2
```

**Shell fallback for the briefing only** (no agent, no scaffold):

```bash
bash install-claude.sh /path/to/project  # writes or merges .claude/CLAUDE.md
bash install-codex.sh /path/to/project   # writes or merges AGENTS.md
```

## What it actually does

**Coordinates across repos, for real.** Drop child repos in as git submodules and Cliplin recognizes it's coordinating, not working alone — no flag, no config. It dispatches a lightweight scout to each candidate repo first (cheap relevance check), then a full worker only where it matters. Tested against a real multi-repo open-source project (Express.js's core + two of its middleware packages) — confirmed working end to end, including the escalation path when a child repo has no specs yet.

**Bootstraps specs from code that has none.** Point `reverse-engineer` at an unspecced repo and it reads the README, the source, the tests — and proposes real ADRs, TDRs, and `.feature` files grounded in what the code actually does, gaps and all. Run against a real, unmodified open-source package: 2 ADRs, 4 TDRs, 12 scenarios, zero lines of source code touched.

**Validates mechanically, not on faith.** `cycle-validate` doesn't just say "checks passed" — it writes the evidence for each check to a JSON report on disk before it tells you anything. Pass or fail, every time.

**Pulls in shared governance without a package manager.** `knowledge-bundle` installs git-sourced packages of TDRs, ADRs, skills, and templates — the same idea as a preset system, minus the CLI, minus the catalog service. Priority resolves overlap between sources automatically; a genuine contradiction always gets escalated to you, never silently decided.

**Traces every feature to why it exists.** The `@constraints` block on every `.feature` file names exactly which TDRs and ADRs govern it, records any conflict found between them, and lists the specific conditions that would make the agent stop and ask instead of guessing. Nothing ships without that trail.

## How it's built

Three-part specification model, kept deliberately small:

| Artifact | Answers | Lives in |
|---|---|---|
| `.feature` (Gherkin) | What the system does, and why | `docs/features/` |
| TDR | How to build it correctly | `docs/tdrs/` |
| ADR / business doc | Why this decision, over the alternatives | `docs/adrs/`, `docs/business/` |

Every TDR/ADR carries a `find_via`-linked concept map (`context-summary.yaml`) so an agent can answer "was this already decided?" by reading one small file before searching anything else.

## Measured against GitHub Spec Kit

We didn't take our word for it — we installed both, ran the same multi-repo scenario against the same real open-source repos, and read each other's actual source instead of assuming. Full write-up, live evidence, and a scored comparison across 10 dimensions (including where Spec Kit wins outright) in the project's own governance docs. Short version: Spec Kit is more mature and easier to read as a single document; Cliplin is the only one of the two that coordinates multiple repos or bootstraps specs from code that has none — verified, not claimed.

## What's not done yet

No pre-commit hook — a failed validation report doesn't block a commit today, it's visible but not enforced. No catalog or search for knowledge bundles — you add them by git URL. No production track record beyond the sessions that built this. None of that is hidden in the docs; `docs/adrs/000-cliplin-v2-agent-native.md` lists it as a Consequence, not a surprise you find later.

## Learn more

- `docs/business/cliplin-framework.md` — what Cliplin is and why it's shaped this way
- `docs/business/acd-framework.md` — the delivery discipline every cycle follows
- `docs/adrs/000-cliplin-v2-agent-native.md` — the full set of architectural decisions and their trade-offs
- `docs/tdrs/` — every technical rule the agent follows, in plain text you can read in five minutes each
