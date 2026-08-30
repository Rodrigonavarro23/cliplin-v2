---
tdr: "1.0"
id: "knowledge-bundle-management"
title: "Knowledge Bundle Management — Presets Without a CLI"
summary: "A knowledge bundle is a git-sourced package of TDRs/ADRs/skills/templates installed under .cliplin/knowledge/<name>/, declared in .cliplin/bundles.yaml, resolved by priority on conflict. Adapts GitHub Spec Kit's preset system, without a CLI — a skill does the work."
---

# rules

## Resolution note (why this file exists)

Scoring this project against GitHub Spec Kit found a real capability gap: presets (versioned, domain-specific template/terminology packages, e.g. their real `architecture-governance` preset) with priority-based conflict resolution. This project adopts the same underlying idea — packages installed under `.cliplin/knowledge/<name>-<source>/` via git sparse checkout, supporting multi-package repos — with two additions: (1) a skill-driven way to do this without a CLI, and (2) priority resolution when two installed bundles conflict.

## What a bundle is (MUST understand)

A git repository (or a nested subfolder of one, for multi-package repos, per the reference layout convention) containing any of: `tdrs/`, `adrs/`, `plugins/cliplin-v2/skills/`, `plugins/cliplin-v2/templates/`. Installed under `.cliplin/knowledge/<name>-<source_normalized>/`, same directory convention as the reference mechanism.

## Manifest (MUST follow)

`.cliplin/bundles.yaml`, project root:

```yaml
bundles:
  - name: <string>            # bundle identifier, may be a nested path for multi-package repos (e.g. "aws/sqs")
    source: <git url>
    version: <git ref>        # tag, branch, or commit
    priority: <int>           # higher wins when two bundles conflict on the same concept; default 0
    enabled: true              # default true if absent
```

## Installation (MUST follow)

Uses `git` directly (already a dependency of this project via submodules and `git log` in `deterministic-context-discovery`) — no new binary, no CLI, per `docs/tdrs/plugin-packaging.md`. For a nested `name` (multi-package repo), use `git sparse-checkout` scoped to that subfolder, so bundle authors can host several bundles in one repo without restructuring anything.

## Discovery integration (MUST follow — evolves `docs/tdrs/deterministic-context-discovery.md`)

`deterministic-context-discovery`'s fan-out (Glob step) MUST also search `.cliplin/knowledge/**`, not only `docs/`. This is the same scope the external reference `context.md` rule already used — extending our own glob patterns to match it, not inventing a new search path.

`context-summary-sync` MUST fold in concepts/rules from enabled bundles the same way it folds in project-native TDRs/ADRs — a bundle's content is discoverable through `context-summary.yaml` exactly like project-owned specs. This is what keeps existing artifacts working unchanged: nothing about `.feature`, `@constraints`, or `context-summary.yaml`'s schema changes to accommodate bundles — bundles just add more `find_via` targets.

## Priority and conflict resolution (MUST follow)

If `deterministic-context-discovery` matches TDRs/ADRs from two or more enabled bundles (or a bundle and a project-native doc) on the same concept:

- If their content is **compatible** (one is more specific, or they simply don't contradict): the higher-`priority` bundle's doc is cited first in `governed_by`; the other(s) may still be listed if genuinely relevant.
- If their content **actually contradicts** (not just overlaps): this is a `[CONFLICT]` per `docs/tdrs/feature-constraints-format.md` — priority does NOT silently resolve a real contradiction, it only breaks ties between compatible-but-overlapping sources. A genuine conflict always surfaces to the human, same as any other conflict.
- Project-native `docs/tdrs/`/`docs/adrs/` are implicitly highest priority unless a bundle is explicitly given a higher number — a project's own decisions are not silently overridden by an installed package.

## Skill actions (implemented by `plugins/cliplin-v2/skills/knowledge-bundle/SKILL.md`)

`list`, `add <source> [--name] [--version] [--priority]`, `remove <name>`, `update <name>`, `show <name>` — same verb set as the reference `cliplin knowledge` CLI, invoked as skill actions instead of CLI flags since this project has no CLI.

## Explicit non-goals

- No public catalog/search (`preset search` against a hosted registry) — that requires infrastructure (a catalog service) this project doesn't have and doesn't need for its current scope. Bundles are added by direct git URL.
- No bundle-building (`.zip` distributable) — out of scope; a bundle IS a git repo, nothing to package further.

code_refs:
  - "docs/tdrs/plugin-packaging.md"
  - "docs/tdrs/deterministic-context-discovery.md"
  - "docs/tdrs/context-summary-format.md"
  - "docs/tdrs/feature-constraints-format.md"
