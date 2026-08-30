---
name: knowledge-bundle
description: >-
  Manage knowledge bundles — git-sourced packages of TDRs/ADRs/skills/templates
  installed under .cliplin/knowledge/<name>/, declared in .cliplin/bundles.yaml.
  Actions: list, add, remove, update, show. Priority-based conflict resolution
  when two bundles (or a bundle and a project doc) disagree on the same concept.
when_to_use: >-
  Use when the human wants to install, remove, update, or inspect a domain
  knowledge package (e.g. an accessibility-governance or security-architecture
  bundle) for this project. Do NOT use to author project-native TDRs/ADRs — that's
  cycle-init's job; this skill only manages externally-sourced packages.
---

# Skill: knowledge-bundle

Implements `docs/tdrs/knowledge-bundle-management.md`.

## `list`

Read `.cliplin/bundles.yaml` if it exists. Report each entry: name, source, version, priority, enabled/disabled, and whether `.cliplin/knowledge/<name>-<source_normalized>/` actually exists on disk (installed) or not (declared but missing — a drift signal). If the manifest doesn't exist, report no bundles declared.

## `add <source> [--name] [--version] [--priority]`

1. If `.cliplin/bundles.yaml` doesn't exist, create it from an empty `bundles: []` skeleton.
2. Derive `name` from the source URL if not given (last path segment).
3. Clone via `git` into `.cliplin/knowledge/<name>-<source_normalized>/` — use `git sparse-checkout` scoped to the nested subfolder if `name` implies one (multi-package repo, per `docs/tdrs/knowledge-bundle-management.md`).
4. Append the entry to `.cliplin/bundles.yaml` (`priority` defaults to `0`, `enabled` defaults to `true` if not given).
5. Invoke `context-summary-sync` to fold in the newly installed bundle's concepts/rules.
6. Report what was installed and its resolved priority relative to existing bundles.

## `remove <name>`

1. Delete `.cliplin/knowledge/<name>-<source_normalized>/` from disk.
2. Remove the entry from `.cliplin/bundles.yaml`.
3. Invoke `context-summary-sync` — per its additive-but-drift-aware rule (`docs/tdrs/context-summary-format.md`), entries whose `find_via` pointed only into the removed bundle are dropped on the next regeneration.

## `update <name>`

Re-clone/re-sync at the currently configured `version` (or a new one if the human specifies), then re-run `context-summary-sync`.

## `show <name>`

Report the manifest entry plus a listing of what the bundle actually contains on disk (`tdrs/`, `adrs/`, `skills/`, `templates/` — whichever are present).

## Conflict resolution (MUST follow, per `docs/tdrs/knowledge-bundle-management.md`)

When `deterministic-context-discovery` or `context-summary-sync` finds two sources (bundle vs. bundle, or bundle vs. project-native doc) covering the same concept:

- Compatible content → cite the higher-`priority` source first in `governed_by`; project-native docs are implicitly highest priority unless a bundle is explicitly configured higher.
- Genuinely contradictory content → `[CONFLICT]`, always escalated to the human. Priority never silently overrides a real contradiction — it only orders compatible, overlapping sources.

## Constraints (MUST follow)

- Never install, remove, or update a bundle without the human having asked for it in this session — no automatic bundle management triggered by `cycle-init` or `cycle-run`.
- Existing artifact schemas (`.feature`, `@constraints`, `context-summary.yaml`) never change to accommodate bundles — a bundle is just more content at more paths, discovered through the same mechanisms already in place.
