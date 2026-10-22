---
name: spec-review
description: >-
  Read-only review of how a repo's specs are written — features and their @constraints, TDRs,
  ADRs, business docs and context-summary.yaml — against Cliplin's own framework rules only:
  a deterministic lint plus a judgment pass. Every finding cites path:line, its rule and source,
  a severity and whether its fix is editorial or needs a new cycle. Writes a local report under
  .cliplin/reviews/, or nothing at all in result-only mode. Never edits a spec.
when_to_use: >-
  Use when asked to review, audit or check the specs ("spec review", "revisá los specs") of the
  whole docs/ tree, some paths, one feature, or what changed since a git ref; or when an agent
  orchestrating Cliplin needs a spec review before a human approval or inside a code review.
  Do NOT use to write or fix specs (cycle-init), or to check that code matches its specs
  (cycle-run / cycle-validate).
---

# Skill: spec-review

Implements `docs/tdrs/spec-review.md` (Cliplin framework repo). Covers `docs/features/spec-review.feature`.

You review **how the specs are written**, never whether the code does what they say. You return
findings and concrete improvements; you never fix anything yourself.

## Hard limits (MUST)

- **Read-only on the repo.** Never edit `docs/`, `.cliplin/context-summary.yaml`, a tag or code.
  Never run `cycle-init`, `cycle-run`, `context-summary-sync`, tests, or a git command that
  changes state. In `report` mode the only files you write are the two under `.cliplin/reviews/`;
  in `result-only` mode you write **nothing anywhere** (no report, no lint output, no temp file).
- **Framework rules only.** Report only what the catalog below states, each finding naming its
  check id and source. A project's own writing conventions are never findings — e.g. dated
  `(Amended …)` / `RESOLVED` notes, a `## History` heading, area or category folders, PRD status
  lines. A framework defect no id covers is `J-99`, named in plain words with its source.
- **Evidence or nothing.** Every finding cites `path:line` and quotes the offending text (≤ 2
  lines). A lint finding you have not opened is reported as `lint, not verified` — never as verified.
- **The `Feature:` description is human-owned.** Flag it; never propose replacement text ("for the
  human to reword").
- **Language is not a defect.** Spanish or English are both fine; only a switch inside one
  document is `minor`.
- Size limits are heuristics and are labelled `heuristic`.

## 1. Resolve scope and mode

- **Scope**: whole tree (default); one or more paths; a feature slug (→ the `.feature`, its
  `<slug>.checklist.md` and every doc in its `governed_by`); or `--since <ref>` — pass it to the
  lint (`--since <ref>`), which lists the specs changed since that reference (committed, staged,
  unstaged or untracked; deleted ones skipped). Review exactly that list; the documents they rely
  on are read only as excerpts. Without the lint, build the same list with
  `git diff --name-only <ref>...HEAD`, `git diff --name-only HEAD` and
  `git ls-files --others --exclude-standard`, keeping `docs/**/*.feature|*.md` and
  `.cliplin/context-summary.yaml`.
- **Mode**: `report` (default) or `result-only` — chosen when the caller asks for it, or when the
  working copy may not be written (a read-only harness). When unsure whether you may write, use
  `result-only`.
- Announce the scope, the mode and the review id `spec-review-YYYY-MM-DD[-<scope-slug>]`.

## 2. Mechanical pass (lint)

The lint ships next to this file: `<this skill's directory>/lint.py` (standard library only).

- `report` mode:
  ```bash
  mkdir -p .cliplin/reviews
  python3 -I <skill dir>/lint.py --root . [PATH ...] > .cliplin/reviews/<review-id>.lint.tsv
  ```
- `result-only` mode — run it and read its output; **never redirect it to a file**:
  ```bash
  python3 -I <skill dir>/lint.py --root . [PATH ...]
  ```

No PATH = whole tree with the cross-file checks (duplicate ids, orphans, context-summary reach).
Output: TSV `severity  check_id  path:line  fix  message`; counts on stderr. Open at least one
finding per check id you report and confirm it; drop any false one and list it under calibration
with the check id that produced it.

Check first with `command -v python3`. If `python3` is missing or the script cannot run, skip this pass, run the judgment pass alone, and
say in the answer (and the report) that the lint was unavailable and why.

## 3. Judgment pass (reading)

Read until done, and record which files you read in full and which you only sampled:

1. Every file of an explicit scope (path / slug / since). Checks that need neighbours (J-11) MAY
   read **excerpts** of other docs (`grep -n` + a few lines), listed as "consulted (excerpt)".
2. Whole tree: every feature's `@constraints` block and `Feature:` header; then the 5 largest
   features and the 5 largest TDRs in full (`wc -l`); then the files with most lint findings; then
   3 scenarios of each remaining feature.

Apply the judgment checks (J-*) of the catalog to what you read.

## 4. Classify every finding

Each finding carries:

- **severity** — `blocker` (breaks a MUST that gates a cycle: `cycle-run` cannot start, Gherkin
  does not parse) · `major` (another framework MUST) · `minor` (a framework template or
  convention) · `info` (heuristic or suggestion). Use the catalog's default; change it only with a
  reason written in the finding.
- **fix type** — `editorial` (form only: tags, fields, paths, frontmatter, headings, structure,
  wording that keeps what is said) or `requires cycle-init` (the fix changes what a scenario or
  rule says the system does). The lint's `fix` column gives the mechanical ones.

Group a defect repeated across many files as one pattern (count + 3 examples), not N rows.

## 5. Output

Write in the human's language (check ids and quoted text as they are), with this structure:

```markdown
# Spec review — <scope> — <YYYY-MM-DD>

## Summary
- Scope: <scope>; files: N features, N TDRs, N ADRs, N other.
- Coverage: read in full <list>; sampled <list>; consulted (excerpt) <list>.
- Findings: blocker N · major N · minor N · info N (lint verified N, lint not verified N, judgment N).
- Lint: ran | unavailable (<why>).
- Verdict: <one line>.

## Top improvements (max 10)
1. **<what to change>** — <why, rule (source)>. Files: <paths>. Fix: editorial | requires cycle-init.

## Findings by document
### <path>
| id | sev | line | evidence | rule (source) | fix | proposed improvement |
|---|---|---|---|---|---|---|

## Cross-cutting patterns

## Lint, not verified
<lint findings you did not open, as `check_id path:line message` — never mixed into the tables above>

## Lint calibration
- False positives: <check id, example, why> (or "none")
- False negatives: <defects found by reading that the lint should catch> (or "none")

## Out of scope
```

- **`report` mode**: write it to `.cliplin/reviews/<review-id>.md`, then answer in ≤ 20 lines:
  report path, counts by severity, top 5 improvements, one coverage line.
- **`result-only` mode**: the whole structure above **is** the answer. Nothing is written.

## Check catalog (Cliplin framework rules only)

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
| T-03 | minor | `
