---
name: context-summary-sync
description: >-
  Regenerates .cliplin/context-summary.yaml for the current repo at the close of a
  cycle-run session, adding any concept or rule introduced or relied upon that is
  not yet captured.
when_to_use: >-
  Invoked automatically as the last step of cycle-run, after cycle-validate passes.
  Do not invoke standalone outside of a cycle close — this skill assumes a just-closed
  session's governing docs and feature changes are already on disk.
---

# Skill: context-summary-sync

Implements the lifecycle rules in `docs/tdrs/context-summary-format.md`.

## Procedure

1. Read the current `.cliplin/context-summary.yaml` if it exists; otherwise start from the schema skeleton in `templates/context-summary.template.yaml`.
2. From the session that just closed, collect:
   - Every path added to `governed_by` in the `.feature` file's `@constraints` block during this session.
   - Every new domain term introduced in the `Feature:`/`Scenario:` text that isn't already a `concepts` entry.
   - Every rule stated in a newly created or newly referenced TDR that isn't already a `rules` entry.
3. For each new concept: add `{ term, definition, find_via: [<the governing doc path(s)>] }`. Prefer the most specific governing doc as the first `find_via` entry.
4. For each new rule: add `{ id, summary, source }`. Generate `id` as the next unused `R-NNN` in sequence.
5. Set `last_cycle` to an identifier for this session (e.g. the feature slug plus date).
6. Write the file back to `.cliplin/context-summary.yaml`.

## Rules (MUST follow)

- Never remove an existing `concepts`/`rules` entry just because this session didn't touch it — this is additive, not a full regeneration from scratch, unless a governing doc referenced by `find_via`/`source` no longer exists on disk (drift), in which case remove that specific stale entry only.
- Do not hand-edit this file outside of this skill's procedure — it is a derived artifact (see `docs/tdrs/context-summary-format.md`, "Lifecycle").
