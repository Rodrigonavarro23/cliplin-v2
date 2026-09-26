# Cliplin v2

**Spec-first AI development, agent-native.** Supports Claude Code and Codex. No framework CLI, binary, or vector database. Coordinates across repos out of the box.

Cliplin v2 is a dual-host plugin made from plain text and shell. It turns Claude Code or Codex into a disciplined spec-first development partner: every feature gets a Gherkin spec with a forced governance trail before a line of code exists, every implementation session closes with a validation report written to disk, and it knows the difference between "this repo works alone" and "this repo coordinates three others" without you ever setting a flag.

## Why this exists

Most spec-first AI tooling stops at one repo and trusts the model to remember the rules. Neither of those is good enough once you're past a single project:

- **Real projects span multiple repos.** A feature that touches an API and its three consumers needs something smarter than "hope the agent figures out which repos matter." Cliplin reads `.gitmodules`, recognizes when it's coordinating instead of working alone, and delegates to scoped sub-agents — verified against real multi-repo open-source projects, not a diagram.
- **"The model should remember to validate" isn't a real guarantee.** Cliplin's `cycle-validate` writes an evidence-backed report to disk — `.cliplin/cycles/<id>.json` — every time, pass or fail, before it tells you anything. You can check whether validation actually ran without re-reading the conversation.
- **Semantic search is the wrong tool for a folder of markdown.** Specs are small, structured, and path-routable. Cliplin finds them with `grep`/`glob`/`read`, orchestrated by the model's own reasoning — no embeddings, no index to keep in sync, no server to run.

## Install

The plugin payload under `plugins/cliplin-v2/` is shared by both hosts. Only the
manifest, marketplace and installer are host-specific.

### Claude Code

**Via Claude Code's plugin marketplace** — verified working, no publishing required:

```bash
claude plugin marketplace add /path/to/cliplin-v2
claude plugin install cliplin-v2@cliplin
```

Or use the repository installer:

```bash
bash install-claude.sh --marketplace
```

Confirmed end to end with `claude plugin list` (`Status: ✔ enabled`), not just a documented file layout. Once this repo has a real git remote, swap the local path for it and anyone can install without cloning first.

**Local dev loop, no install at all:**

```bash
claude --plugin-dir /path/to/cliplin-v2/plugins/cliplin-v2
```

Loads for one session, `/reload-plugins` picks up edits — fastest way to iterate on the plugin itself.

**`install.sh` / `install-claude.sh --global` fallback** (personal scope,
`~/.claude/skills/cliplin-v2/`) still works too, but don't run it alongside the
marketplace install — same plugin name, one will silently lose.

### Codex

```bash
codex plugin marketplace add /path/to/cliplin-v2
codex plugin add cliplin-v2@cliplin
```

Or use:

```bash
bash install-codex.sh --marketplace
```

To add persistent Cliplin guidance to one project without overwriting an existing
instructions file:

```bash
bash install-claude.sh /path/to/project  # writes or merges .claude/CLAUDE.md
bash install-codex.sh /path/to/project   # writes or merges AGENTS.md
```

## Quick start

Open Claude Code or Codex in your project and ask for what you want:

```
Add support for rate-limiting the login endpoint.
```

Cliplin's `cycle-init` skill takes it from there: checks whether this is new behavior or an evolution of something that already exists, loads the context that actually governs it, asks you up to 3 sharp questions if (and only if) it's genuinely ambiguous, and drafts a `.feature` file with a `@constraints` block naming exactly which decisions govern it — before proposing any code. Approve it, and `cycle-run` implements it in small, atomic sessions that close with a written validation report.

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
