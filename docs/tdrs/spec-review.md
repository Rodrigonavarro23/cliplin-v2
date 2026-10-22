---
tdr: "1.0"
id: "spec-review"
title: "Spec Review — Read-Only Review of How Specs Are Written, Against Cliplin's Own Rules"
summary: "The spec-review skill reviews a repo's specs for form and style against Cliplin's framework rules only — a deterministic lint plus a judgment pass — and returns cited findings with severity and fix type, as a local report or in its answer alone, never editing a spec."
---

# rules

## What it reviews (MUST follow)

- Spec review judges **how specs are written**, never whether the code does what they say. Its inputs are `docs/features/*.feature` (and their `*.checklist.md`), `docs/tdrs/**/*.md`, `docs/adrs/**/*.md`, `docs/business/**/*.md` and `.cliplin/context-summary.yaml`.
- It applies **Cliplin's framework rules only** — the catalog below, each check naming the framework document it comes from. A project's own conventions are never findings: a check that no framework document states is not in the catalog (e.g. "rewrite, don't patch" markers such as `RESOLVED` or `(Amended …)`, area folders for TDRs, a `## History` heading, ADR category folders, PRD status lines).
- It is **read-only on the repo**. It never edits a spec, a tag, `context-summary.yaml` or code, never runs `cycle-init`, `cycle-run`, `context-summary-sync`, tests or a git command that changes state. In report mode the only files it writes are its report and the lint's raw output under `.cliplin/reviews/`.

## Scope and modes

- **Scope**: the whole tree (default); one or more paths; a feature slug (the `.feature`, its checklist and every doc in its `governed_by`); or `--since <ref>` (the specs changed in `git diff --name-only <ref>...HEAD`, plus uncommitted ones).
- **Output mode**:
  - `report` (default): writes `.cliplin/reviews/<review-id>.md` (`<review-id>` = `spec-review-YYYY-MM-DD[-<scope-slug>]`) and `.cliplin/reviews/<review-id>.lint.tsv`, and answers with a summary of at most 20 lines (report path, counts by severity, top five improvements, one coverage line). Reports are local working files like `.cliplin/cycles/`; the skill never edits `.gitignore`.
  - `result-only`: writes nothing anywhere. The findings, grouped as in the report, are the answer. The lint's output is read from the command, never redirected to a file. This is the mode for a read-only harness.

## The lint (mechanical pass)

- `skills/spec-review/lint.py`, run as `python3 -I <plugin root>/skills/spec-review/lint.py [--root <repo>] [PATH ...]`, standard library only (`docs/tdrs/plugin-packaging.md`). It only reads and prints one finding per line as TSV `severity<TAB>check_id<TAB>path:line<TAB>fix<TAB>message` (`fix` is `editorial` or `requires-cycle-init`), counts to stderr. With no PATH it checks the whole tree including cross-file checks (X-01, C-04).
- Heuristic thresholds live at the top of the script and are labelled `heuristic` in their findings.
- A lint finding the reviewer has not read is reported as `lint, not verified`, never as verified. At least one finding per reported check id is opened and confirmed; a false one is dropped and listed under calibration with the check id that produced it.
- When `python3` is not available or the script is missing, the review runs the judgment pass only and says, in the report and the answer, that the lint was unavailable and why.

## The judgment pass

- Reads in order until done: every file of an explicit scope (neighbouring docs only as excerpts); for the whole tree, every feature's `@constraints` block and `Feature:` header, then the five largest features and five largest TDRs in full, then the files with most lint findings, then three scenarios of each remaining feature. The review records which files it read in full and which it sampled.

## Findings

- Every finding cites `path:line`, quotes the offending text (at most two lines), names its check id and its framework source, and states:
  - **severity**: `blocker` (breaks a MUST that gates a cycle — `cycle-run` cannot start, Gherkin does not parse), `major` (violates another framework MUST), `minor` (violates a template or convention of the framework), `info` (heuristic or suggestion);
  - **fix type**: `editorial` (form only — tags, fields, paths, frontmatter, headings, structure, wording that keeps what is said) or `requires cycle-init` (the fix changes what a scenario or rule says the system does).
- The `Feature:` description is human-owned: a finding there never proposes replacement text.
- Language of a spec is never a defect; only a switch of language inside one document is `minor`.
- A defect repeated in many files is one pattern entry (count and three examples), not one row per file.
- Report sections: summary (scope, coverage, counts, verdict line), top-10 improvements, findings per document, cross-cutting patterns, lint calibration (false positives, false negatives), out of scope.

## Catalog (framework rules only)

The `sev` column is the check's default; a sub-case may carry another severity, stated in its finding (e.g. an empty `governed_by` is a blocker within F-02, a key outside the schema minor). `J-03` and the F-01/F-02/F-10 sub-cases whose fix needs new content (no `@constraints`, empty `governed_by`, a scenario without When/Then, a feature without scenarios) are `requires cycle-init`; every other mechanical finding is `editorial`.

| id | sev | rule | source |
|---|---|---|---|
| F-01 | blocker | `@constraints` is a tag line directly followed by `#` lines and then `Feature:` | feature-constraints-format |
| F-02 | major | `governed_by` (non-empty), `conflicts`, `gaps`, `escalation_triggers` present; `[]` when none; any other key is minor | feature-constraints-format, spec-quality-checklist |
| F-03 | blocker | every `governed_by` path exists | feature-constraints-format, cycle-validate-report |
| F-04 | major | every `@constraints` line prefixed `# ` | feature-constraints-format |
| F-05 | minor | each scenario has `@type` and `@status` (missing one: major); `@status:implemented` and `@status:modified` carry `@changed` (`@status:new` need not — the feature template has none); tag order `@type` → `# why:` → `@priority` → `@status` → `@changed` (→ `@reason`) | scenario-priority, feature template, cycle-run close, cycle-init evolution |
| F-06 | major | `@type:edge`/`@type:complementary` carries a `# why:` citing its source | spec-quality-checklist |
| F-07 | major | tag values valid (`main/edge/complementary`, `new/modified/implemented/deprecated`, `P1–P3`, ISO date); no tag repeated | scenario-priority |
| F-08 | major | `@status:modified` carries `@changed` and `@reason` | cycle-init evolution |
| F-09 | minor | `Feature:` description has an actor / capability / benefit (As/I want/So that, any language) — flag only | feature template |
| F-10 | blocker | valid Gherkin: Given → When → Then, one When, a Then, Outline ⇔ Examples, unique scenario names | spec-quality-checklist |
| F-11, F-12 | info | long steps; feature > 500 lines or > 30 scenarios, scenario > 8 steps, `governed_by` > 15 | heuristic |
| F-14 | info | `@status:new`/`modified` left on scenarios whose cycle report closed them | cycle-validate-report |
| F-16 | minor | `governed_by` cites a `.feature` instead of TDR/ADR/business docs | feature-constraints-format |
| F-17 | info | a step with an HTTP verb and path, a status code or an ENV_VAR-like token (quoted text exempt) | spec-quality-checklist |
| J-01 | minor | no implementation detail in feature and scenario text | spec-quality-checklist |
| J-02 | minor | observable language; `Then` asserts what a person or caller can observe | spec-quality-checklist |
| J-03 | major | each scenario independent: its `Given` sets up everything | spec-quality-checklist |
| J-04 | minor | one behavior per scenario; Outline instead of near-duplicates | spec-quality-checklist |
| J-05 | minor | `gaps` hold open questions only; `escalation_triggers` are specific situations; `conflicts` non-empty only while unresolved | feature-constraints-format |
| J-06 | info | one feature = one capability; name the split when sub-domains separate | heuristic, cycle-run session size |
| J-07 | info | `<slug>.checklist.md` present | spec-quality-checklist |
| T-01 | major | frontmatter exactly `tdr: "1.0"`, `id` (kebab-case, unique), `title`, `summary` | tdr template |
| T-02 | minor | body opens with `# rules` | tdr template |
| T-03 | minor | `code_refs:` at the end, non-empty, paths exist | tdr template |
| T-06 | info | summary is one sentence (≤ 350 characters); file ≤ 250 lines | tdr template, heuristic |
| J-10 | minor | rules read as rules (MUST/SHOULD/MAY, lists, tables), rationale short | tdr template |
| J-11 | minor | one owner per rule: the same rule in two TDRs is kept in one and referenced | context-summary-format |
| A-01 | major | `# ADR-NNN: <Title>`, number = file prefix, unique | adr template |
| A-02 | minor | `## Status` (Proposed/Accepted/Deprecated/Superseded/Rejected), `## Context`, `## Decision`, `## Consequences` with `### Positive`/`### Negative` | adr template |
| A-05 | minor | a `Superseded` ADR names its successor, which links back | adr template |
| C-01 | major | `context-summary.yaml` has `concepts`, `rules`, `last_cycle` | context-summary-format |
| C-02 | major | no duplicate term or rule id | context-summary-format |
| C-03 | major | every `find_via`/`source` entry exists (a path named inside a definition is prose, not an entry) | context-summary-format |
| C-04 | minor | every TDR reachable from some concept or rule | context-summary-format |
| J-30 | minor | `last_cycle` names the latest closed cycle; definitions one line | context-summary-format |
| X-01 | info | orphan TDR/ADR: nothing references it | cycle-validate-report |
| X-02 | minor | a backticked `docs/` path in prose does not exist (ADRs: info); Cliplin state paths (`.cliplin/…`), folder references and placeholders are not checked | cycle-validate-report |
| X-03 | minor | a quoted section after a `.md` path is not a heading or text of that doc | cycle-validate-report |
| J-99 | minor | a framework-rule defect no id covers, named in plain words with its source | — |

code_refs:
  - "plugins/cliplin-v2/skills/spec-review/SKILL.md"
  - "plugins/cliplin-v2/skills/spec-review/lint.py"
