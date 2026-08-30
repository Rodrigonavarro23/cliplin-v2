# ADR-000: Cliplin v2 — Agent and Skill Compendium (Agent-Native, No CLI or Binaries)

## Status
Accepted

## Context

Prior research and prototyping around spec-first AI-assisted development identified a recurring set of problems in that space:

1. Context-layer fragmentation: divergent context server (RAG/vector DB) implementations with no clear canonical one, configuration pointing at one mechanism while the actual code implements another.
2. The semantic RAG mechanism (embeddings + vector DB) is over-engineering for the typical spec corpus of a spec-first project (small, structured, path-routable text files), and additionally lacks chunking, truncating long specs.
3. Flow enforcement ends up being mostly imperative prose in rule files, not code — the agent can skip context loading with nothing mechanically preventing it.
4. An agent delivery framework (equivalent to ACD, Agentic Continuous Delivery) treated as an optional extension instead of the default flow generates real redundancy: two non-identical field schemas for the same constraints artifact (see `docs/tdrs/feature-constraints-format.md` in this project).
5. Host plugins that bundle compiled binaries per architecture even though their real value content is text (skills, shell hooks).
6. Multi-agent coordination patterns (self-describing node state contract, coordinator↔worker communication protocol, worktree isolation) are valuable, but a standalone persistent-daemon model has high adoption friction against already-installed tools (Claude Code, Cursor).

## Decision

Cliplin v2 is a **new, independent project**: a distributable compendium of Skills + sub-agent definitions for AI hosts (Claude Code first, via plugin), with no CLI of its own, no compiled binary, and no MCP server with a vector DB as the default mechanism.

Adopted principles:

1. **ACD is the native default flow**, not an optional knowledge package. The command vocabulary is expressed as native skills (`cycle-init`, `cycle-run`, `cycle-validate`) — see `docs/tdrs/cycle-commands.md`.
2. **Deterministic context discovery**, no embeddings or vector DB: search fan-out via native host tools (grep/glob/read), orchestrated by skill — see `docs/tdrs/deterministic-context-discovery.md`.
3. **Recursive, flagless mono-repo/multi-repo mode detection**: presence of `.gitmodules` determines whether the agent acts as coordinator (delegates) or worker (executes locally) — see `docs/tdrs/multi-repo-coordination.md`.
4. **`context-summary.yaml` per repo** as a concept/rule map (not a file map), generated/updated at the close of each ACD cycle — see `docs/tdrs/context-summary-format.md`.
5. **Packaged as a host plugin, no binaries**: manifest + skills + agents + shell hooks only — see `docs/tdrs/plugin-packaging.md`.
6. **Validation (`cycle-validate`) as a step of the interactive flow for now**, not a mechanical git hook — the pre-commit hook is deferred to a future cycle, out of scope for this ADR. **Superseded in part 2026-08-28: a consuming project built one. See the amendment below — the deferral held for `cycle-validate` itself, not for commit-time validation.**

## Consequences

### Positive
- Eliminates context-server duplication (two RAG implementations) by not depending on either for the default flow.
- Stronger enforcement than spec-kit: `.feature` keeps Gherkin grammar (potentially executable as a test), and the native ACD cycle forces `@constraints` with `governed_by`/`conflicts`/`gaps`/`escalation_triggers` from the first command.
- Minimal adoption friction: installs as a plugin inside already-adopted tools (Claude Code), no build toolchain or standalone daemon process.
- Cross-repo coordination reuses the host's native sub-agent mechanism (Agent/Task tool) instead of rebuilding subprocess dispatch.

### Negative
- No mechanical gate (git hook) at this stage — cycle-close validation depends on the agent deciding to run `cycle-validate`, the same determinism weak point this was meant to solve, explicitly accepted as sequencing debt. **Still true as written 2026-08-28**, and narrower than it looks: a commit-time gate now exists downstream, but it does not check that `cycle-validate` ran. See the amendment.
- Deterministic search (grep/glob) has lower recall than semantic search for paraphrased cross-repo queries; partially mitigated by `context-summary.yaml` as a concept layer, not just a file layer.
- Requires maintaining a translation/adaptation layer per AI host if extended beyond Claude Code.

## Notes
- Index in the `business-and-architecture` collection.
- See `docs/tdrs/feature-constraints-format.md`, `docs/tdrs/cycle-commands.md`, `docs/tdrs/plugin-packaging.md`, `docs/tdrs/context-summary-format.md`, `docs/tdrs/multi-repo-coordination.md`, `docs/tdrs/deterministic-context-discovery.md`.

## Amendment 2026-08-28: a commit-time gate exists downstream — and what it does NOT cover

Recorded because decision 6 and the first negative consequence above were written as *"deferred"* and read, a year of usage later, as *"there is no hook"*. Both halves need separating.

**What changed.** A consuming project (`wedov2`) implements two hooks via `.pre-commit-config.yaml` and `scripts/acd-validate.sh`:

- `acd-commit-validator` (pre-commit stage) — runs the AC/UD/TR checks against the **staged** changes and blocks the commit on failure.
- `acd-commit-msg-validator` (commit-msg stage) — enforces the `ACD-session:` / `Artifacts:` / `Scenarios:` trailers (UD-2).

Neither ships with this framework: the plugin still packages skills and agents only, so decision 5 (**no binaries**) is unaffected. This amendment records that the pattern was proven downstream, not that the framework now provides it.

**What it does NOT do, which is why the negative consequence still stands.** The hook validates *a commit*. It does not verify that `cycle-validate` ran, that a report was persisted, or that the cycle was closed honestly. An agent can still skip `cycle-validate` entirely and, provided the staged artifacts hang together, commit cleanly. The determinism gap this ADR accepted as sequencing debt is **unchanged**; what closed is a different, adjacent gap.

**Why it is worth recording rather than leaving as a downstream detail.** The gate earns its cost. In one day of use it blocked commits over findings a green test suite had not caught, and none were formalities:

- a route group widened to accept a second credential, with no governing spec anywhere;
- a constant-time credential comparison shipped with zero tests;
- an exported method with no production caller, its only consumer left untracked;
- a scenario tagged `@status:implemented` whose code did the opposite — twice, in different features;
- a provider-error classification implemented on one of three routes, leaving the matching handling on the other two unreachable, with tests that hid it by injecting a status the real handler could never produce.

The common shape is worth naming: **every one was a claim the artifacts made that the code did not keep**, and every one was found by reading the call chain, never by running the tests. That is precisely the failure mode a spec-first framework exists to prevent and cannot prevent by itself — the spec asserting something the implementation does not do is invisible to the spec.

**Open, and deliberately not decided here**: whether the framework should package this gate (which would revisit decision 5), and whether a `cycle-validate`-ran check belongs in it at all — the hook sees a commit, while cycle closure is a property of a session, and those two do not line up one to one.
