#!/usr/bin/env python3
"""Deterministic spec lint for a Cliplin v2 repo — the mechanical pass of the spec-review skill.

Cliplin framework rules only (docs/tdrs/spec-review.md "Catalog"); a project's own conventions are
never checked here. Standard library only (docs/tdrs/plugin-packaging.md).

Read-only: it never writes a file. Prints one finding per line as TSV:
    severity<TAB>check_id<TAB>path:line<TAB>fix<TAB>message
Severities: blocker | major | minor | info.  Fix: editorial | requires-cycle-init.
Counts go to stderr.

Usage:
    python3 -I <plugin root>/skills/spec-review/lint.py [--root <repo>] [--since <ref>] [PATH ...]
--since <ref> checks only the specs changed since <ref> (committed, staged, unstaged or untracked),
using read-only git commands; deleted specs are skipped.
With no PATH, every spec under docs/ plus .cliplin/context-summary.yaml is checked, with the
cross-file checks (duplicate ids, orphans, context-summary reach). A PATH may be a file or a directory.
"""
import argparse
import glob
import os
import re
import subprocess
import sys
from datetime import date

# ── Heuristic thresholds (NOT framework rules; tune here) ───────────────────────────────
FEATURE_MAX_SCENARIOS = 30
FEATURE_MAX_LINES = 500
SCENARIO_MAX_STEPS = 8
STEP_MAX_CHARS = 180
TDR_MAX_LINES = 250
TDR_SUMMARY_MAX_CHARS = 350
ADR_MAX_LINES = 250
GOVERNED_BY_MAX = 15

VALID_TYPE = {"main", "edge", "complementary"}
VALID_STATUS = {"new", "modified", "implemented", "deprecated"}
VALID_PRIORITY = {"P1", "P2", "P3"}
TAG_ORDER = ["type", "priority", "status", "changed", "reason"]
STEP_KW = ("Given", "When", "Then", "And", "But", "*")
CONSTRAINT_KEYS = ("governed_by", "conflicts", "gaps", "escalation_triggers")
ENV_LIKE = re.compile(r"\b[A-Z][A-Z0-9]*_[A-Z0-9_]+\b")
STEP_IMPL = re.compile(r"\b(?:POST|GET|PUT|PATCH|DELETE) /|\bstatus is \d{3}\b")
ADR_STATUS = {"Proposed", "Accepted", "Deprecated", "Superseded", "Rejected"}

findings = []


# Fix type per check: does fixing it keep what the spec says (editorial) or change it (a new cycle)?
REQUIRES_CYCLE = {"J-03"}


def add(sev, cid, path, line, msg, fix=None):
    if fix is None:
        fix = "requires-cycle-init" if cid in REQUIRES_CYCLE else "editorial"
    findings.append((sev, cid, f"{path}:{line}", fix, msg))


def read(path):
    with open(path, encoding="utf-8") as fh:
        return fh.read().split("\n")


def nlines(lines):
    """Line count as an editor shows it: the empty string after a trailing newline is not a line."""
    return len(lines) - (1 if lines and lines[-1] == "" else 0)


def exists(root, p):
    p = p.strip().strip('"').strip("'").rstrip("/")
    if any(c in p for c in "*?["):
        return bool(glob.glob(os.path.join(root, p), recursive=True))
    return os.path.exists(os.path.join(root, p))


# ── Frontmatter ─────────────────────────────────────────────────────────────────────────
def frontmatter(lines):
    if not lines or lines[0].strip() != "---":
        return None, 0
    fm = {}
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            return fm, i + 1
        m = re.match(r"^([A-Za-z_-]+):\s*(.*)$", lines[i])
        if m:
            fm[m.group(1)] = m.group(2).strip().strip('"')
    return None, 0


def code_refs(lines):
    out, start = [], None
    for i, l in enumerate(lines):
        if l.strip() == "code_refs:":
            start = i
            continue
        if start is not None:
            m = re.match(r'^\s*-\s*"?([^"]+)"?\s*$', l)
            if m:
                out.append((i + 1, m.group(1)))
            elif l.strip():
                break
    return start, out


# ── Features ────────────────────────────────────────────────────────────────────────────
def lint_feature(root, path):
    lines = read(os.path.join(root, path))
    n = nlines(lines)
    if n > FEATURE_MAX_LINES:
        add("info", "F-12", path, 1, f"{n} lines > {FEATURE_MAX_LINES} (heuristic): consider splitting by sub-domain")

    feat_idx = next((i for i, l in enumerate(lines) if re.match(r"^\s*Feature:", l)), None)
    if feat_idx is None:
        add("blocker", "F-10", path, 1, "no Feature: line (invalid Gherkin)")
        return {}
    # @constraints immediately before Feature: (only comment lines between)
    c_idx = None
    for i in range(feat_idx - 1, -1, -1):
        s = lines[i].strip()
        if s == "@constraints":
            c_idx = i
            break
        if s and not s.startswith("#"):
            break
    if c_idx is None:
        add("blocker", "F-01", path, feat_idx + 1, "no feature-level @constraints block immediately before Feature:", fix="requires-cycle-init")
        governed = []
    else:
        block = lines[c_idx + 1:feat_idx]
        for j, l in enumerate(block):
            if l.strip() and not l.startswith("# ") and l.strip() != "#":
                add("major", "F-04", path, c_idx + 2 + j, "@constraints line not prefixed with '# '")
        text = "\n".join(block)
        for field in CONSTRAINT_KEYS:
            if not re.search(rf"^#\s*{field}:", text, re.M):
                add("major", "F-02", path, c_idx + 1, f"@constraints missing field '{field}' (use [] if none)")
        for j, l in enumerate(block):
            m = re.match(r"^#\s?([A-Za-z_][A-Za-z0-9_-]*):(.*)$", l)
            if not m:
                continue
            key, val = m.group(1), m.group(2).strip()
            if key not in CONSTRAINT_KEYS:
                add("minor", "F-02", path, c_idx + 2 + j, f"key outside schema in @constraints: '{key}'")
            elif key != "governed_by" and val and not val.startswith("["):
                add("major", "F-02", path, c_idx + 2 + j, f"'{key}: {val[:40]}' must be [] or a list")
        governed = []
        in_g = False
        for j, l in enumerate(block):
            s = l.lstrip("#").rstrip()
            if re.match(r"^\s*governed_by:", s):
                in_g = True
                inline = s.split(":", 1)[1].strip()
                if inline and inline != "[]":
                    governed += [(c_idx + 2 + j, x.strip()) for x in inline.strip("[]").split(",") if x.strip()]
                continue
            if in_g:
                m = re.match(r"^\s*-\s*(.+)$", s)
                if m:
                    governed.append((c_idx + 2 + j, m.group(1).split(" #")[0].strip()))
                elif re.match(r"^\s*[a-z_]+:", s):
                    in_g = False
        if not governed:
            add("blocker", "F-02", path, c_idx + 1, "governed_by is empty", fix="requires-cycle-init")
        if len(governed) > GOVERNED_BY_MAX:
            add("info", "F-12", path, c_idx + 1, f"governed_by has {len(governed)} entries > {GOVERNED_BY_MAX} (heuristic): feature may span several domains")
        for ln, g in governed:
            if not exists(root, g):
                add("blocker", "F-03", path, ln, f"governed_by path does not exist: {g}")
            elif g.endswith(".feature"):
                add("minor", "F-16", path, ln, f"governed_by points at a .feature ({g}); framework expects TDR/ADR/business docs")
        for j, l in enumerate(block):
            check_refs(root, path, c_idx + 2 + j, l, "minor")

    # Feature description block: lines after Feature: up to the first tag/comment/keyword
    desc_lines = []
    for i in range(feat_idx + 1, n):
        s = lines[i].strip()
        if re.match(r"^(@|#|Scenario|Example|Background:|Rule:)", s):
            break
        desc_lines.append((i, s))
    desc = " ".join(s for _, s in desc_lines).lower()
    role = re.search(r"\bas (?:a|an|the)\b|\bcomo\b", desc) \
        or any(re.match(r"^(?:as|como)\s", d, re.I) for _, d in desc_lines)
    want = re.search(r"\bi want\b|\bquiero\b", desc)
    goal = re.search(r"\bso that\b|\bpara\b", desc)
    if not (role and want and goal):
        add("minor", "F-09", path, feat_idx + 1, "Feature: description lacks As a / I want / So that (or Como / Quiero / Para); human-owned, flag only")

    # Scenarios
    scen_count = 0
    names = {}
    tags, why_seen = [], False
    statuses = {}
    i = feat_idx + 1
    while i < n:
        s = lines[i].strip()
        if s.startswith("@") and s != "@constraints":
            for t in s.split():
                tags.append((i + 1, t))
        elif s.startswith("#"):
            if s.startswith("# why:"):
                why_seen = True
                kinds = [re.match(r"^@([a-z]+)", t).group(1) for _, t in tags if re.match(r"^@([a-z]+)", t)]
                late = [k for k in kinds if k in ("priority", "status", "changed", "reason")]
                if late:
                    add("minor", "F-05", path, i + 1, f"'# why:' after @{late[0]}: it sits right after @type, before @priority/@status/@changed/@reason")
            check_refs(root, path, i + 1, s, "minor")
        elif re.match(r"^(Scenario|Scenario Outline|Scenario Template|Example):", s):
            scen_count += 1
            name = s.split(":", 1)[1].strip()
            if name in names:
                add("major", "F-10", path, i + 1, f"duplicate scenario name (first at line {names[name]})")
            names.setdefault(name, i + 1)
            check_scenario_tags(path, i + 1, tags, why_seen, statuses)
            end = check_steps(path, lines, i, s.startswith("Scenario Outline") or s.startswith("Scenario Template"))
            tags, why_seen = [], False
            i = end
            continue
        elif s.startswith("Background:") or s.startswith("Rule:"):
            tags, why_seen = [], False
        i += 1
    if scen_count > FEATURE_MAX_SCENARIOS:
        add("info", "F-12", path, feat_idx + 1, f"{scen_count} scenarios > {FEATURE_MAX_SCENARIOS} (heuristic): cycle-run sessions are max 3; consider splitting")
    if scen_count == 0:
        add("major", "F-10", path, feat_idx + 1, "feature has no scenarios", fix="requires-cycle-init")
    for st, c in statuses.items():
        if st in ("new", "modified"):
            add("info", "F-14", path, 1, f"{c} scenario(s) still @status:{st} (open cycle, or a cycle closed without retagging)")
    return statuses


def check_scenario_tags(path, line, tags, why_seen, statuses):
    kinds = {}
    order = []
    for ln, t in tags:
        m = re.match(r"^@([a-z]+)(?::(.*))?$", t)
        if not m:
            add("minor", "F-07", path, ln, f"malformed tag {t}")
            continue
        k, v = m.group(1), m.group(2)
        if k in kinds:
            add("major", "F-07", path, ln, f"tag @{k} repeated on one scenario")
        kinds[k] = (ln, v)
        if k in TAG_ORDER:
            order.append(k)
        if k == "type" and v not in VALID_TYPE:
            add("major", "F-07", path, ln, f"@type:{v} not in {sorted(VALID_TYPE)}")
        elif k == "status" and v not in VALID_STATUS:
            add("major", "F-07", path, ln, f"@status:{v} not in {sorted(VALID_STATUS)}")
        elif k == "priority" and v not in VALID_PRIORITY:
            add("major", "F-07", path, ln, f"@priority:{v} not in P1/P2/P3")
        elif k == "changed":
            try:
                date.fromisoformat(v or "")
            except ValueError:
                add("major", "F-07", path, ln, f"@changed:{v} is not YYYY-MM-DD")
        elif k == "reason" and not v:
            add("minor", "F-07", path, ln, "@reason without a value")
        elif k not in ("type", "status", "priority", "changed", "reason", "wip", "skip"):
            add("info", "F-07", path, ln, f"tag @{k} is not part of the Cliplin vocabulary")
    if "type" not in kinds:
        add("major", "F-05", path, line, "scenario without @type")
    if "status" not in kinds:
        add("major", "F-05", path, line, "scenario without @status")
    else:
        st = kinds["status"][1]
        statuses[st] = statuses.get(st, 0) + 1
        # cycle-run's close adds @changed to implemented scenarios and cycle-init's evolution to modified
        # ones; the feature template creates @status:new without it.
        if st in ("modified", "implemented") and "changed" not in kinds:
            add("minor", "F-05", path, line, f"@status:{st} without @changed:YYYY-MM-DD")
        if st == "modified" and "reason" not in kinds:
            add("major", "F-08", path, line, "@status:modified without @reason")
    tline, t = kinds.get("type", (line, None))
    if t in ("edge", "complementary") and not why_seen:
        add("major", "F-06", path, tline, f"@type:{t} without a '# why:' comment citing its source")
    if order != sorted(order, key=TAG_ORDER.index):
        add("minor", "F-05", path, line, "tag order should be @type → # why → @priority → @status → @changed → @reason; got " + " → ".join(order))


def check_steps(path, lines, start, outline):
    """Validate Given/When/Then of one scenario; return index of the next block."""
    phase = 0  # 0 none, 1 given, 2 when, 3 then
    steps = whens = 0
    has = {"Given": False, "When": False, "Then": False}
    examples = False
    i = start + 1
    in_doc = False
    while i < len(lines):
        s = lines[i].strip()
        if s.startswith('"""') or s.startswith("```"):
            in_doc = not in_doc
            i += 1
            continue
        if in_doc:
            i += 1
            continue
        if re.match(r"^(@|Scenario|Scenario Outline|Scenario Template|Example:|Rule:|Background:|Feature:)", s) and not s.startswith("Examples"):
            break
        kw = s.split(" ", 1)[0] if s else ""
        if kw in STEP_KW:
            steps += 1
            bare = re.sub(r'"[^"]*"', '""', s)  # quoted text is exempt (spec-review F-17)
            hit = STEP_IMPL.search(bare) or ENV_LIKE.search(bare)
            if hit:
                add("info", "F-17", path, i + 1, f"step carries implementation detail ('{hit.group(0)}'): endpoint, HTTP code or env var")
            if len(s) > STEP_MAX_CHARS:
                add("info", "F-11", path, i + 1, f"step of {len(s)} chars > {STEP_MAX_CHARS} (heuristic): likely carries implementation detail or several assertions")
            if kw in has:
                has[kw] = True
                order = {"Given": 1, "When": 2, "Then": 3}[kw]
                if order < phase:
                    add("minor", "F-10", path, i + 1, f"'{kw}' after a later phase: steps should run Given → When → Then")
                phase = max(phase, order)
                if kw == "When":
                    whens += 1
            elif phase == 0:
                add("major", "F-10", path, i + 1, f"scenario starts with '{kw}' instead of Given/When")
        elif s.startswith("Examples:"):
            examples = True
        i += 1
    line = start + 1
    if not has["When"] or not has["Then"]:
        missing = [k for k in ("When", "Then") if not has[k]]
        add("major", "F-10", path, line, "scenario missing " + "/".join(missing), fix="requires-cycle-init")
    if whens > 1:
        add("minor", "F-10", path, line, f"{whens} When steps: one behavior per scenario (split, or move the earlier exchange into Given)")
    if steps > SCENARIO_MAX_STEPS:
        add("info", "F-12", path, line, f"{steps} steps > {SCENARIO_MAX_STEPS} (heuristic): scenario may test several behaviors")
    if outline and not examples:
        add("blocker", "F-10", path, line, "Scenario Outline without Examples")
    if examples and not outline:
        add("major", "F-10", path, line, "Examples under a plain Scenario (use Scenario Outline)")
    return i


# ── TDRs ────────────────────────────────────────────────────────────────────────────────
def lint_tdr(root, path, ids):
    lines = read(os.path.join(root, path))
    fm, body = frontmatter(lines)
    if fm is None:
        add("blocker", "T-01", path, 1, "no YAML frontmatter (tdr/id/title/summary)")
        return
    for k in ("tdr", "id", "title", "summary"):
        if not fm.get(k):
            add("major", "T-01", path, 1, f"frontmatter missing '{k}'")
    extra = set(fm) - {"tdr", "id", "title", "summary"}
    if extra:
        add("minor", "T-01", path, 1, f"frontmatter keys outside the template: {sorted(extra)}")
    if fm.get("tdr") and fm["tdr"] != "1.0":
        add("minor", "T-01", path, 1, f'tdr: "{fm["tdr"]}" (template is "1.0")')
    tid = fm.get("id", "")
    if tid:
        if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", tid):
            add("major", "T-01", path, 1, f"id '{tid}' is not kebab-case")
        ids.setdefault(tid, []).append(path)
    summ = fm.get("summary", "")
    if len(summ) > TDR_SUMMARY_MAX_CHARS:
        add("info", "T-06", path, 1, f"summary is {len(summ)} chars > {TDR_SUMMARY_MAX_CHARS} (heuristic): template asks for one sentence")
    rest = [l for l in lines[body:] if l.strip()]
    if not rest or rest[0].strip() != "# rules":
        add("minor", "T-02", path, body + 1, "first heading after frontmatter is not '# rules'")
    start, refs = code_refs(lines)
    if start is None:
        add("minor", "T-03", path, len(lines), "no code_refs block")
    else:
        if not refs:
            add("minor", "T-03", path, start + 1, "code_refs is empty")
        for ln, r in refs:
            if not exists(root, r):
                add("minor", "T-03", path, ln, f"code_refs path does not exist: {r}")
    if nlines(lines) > TDR_MAX_LINES:
        add("info", "T-06", path, 1, f"{nlines(lines)} lines > {TDR_MAX_LINES} (heuristic): consider splitting by concern")
    lint_prose(root, path, lines, body)


# ── ADRs ────────────────────────────────────────────────────────────────────────────────
def lint_adr(root, path, nums):
    lines = read(os.path.join(root, path))
    m = re.match(r"^# ADR-(\d+):\s*\S", lines[0] if lines else "")
    if not m:
        add("major", "A-01", path, 1, "first line is not '# ADR-NNN: <Title>'")
    else:
        num = int(m.group(1))
        nums.setdefault(num, []).append(path)
        fm = re.match(r"^(\d+)-", os.path.basename(path))
        if fm and int(fm.group(1)) != num:
            add("major", "A-01", path, 1, f"heading number ADR-{num} != file prefix {fm.group(1)}")
    heads = {l.strip(): i for i, l in enumerate(lines) if l.startswith("## ") or l.startswith("### ")}
    for h in ("## Status", "## Context", "## Decision", "## Consequences"):
        if h not in heads:
            add("minor", "A-02", path, 1, f"missing section '{h}'")
    if "## Consequences" in heads:
        for h in ("### Positive", "### Negative"):
            if h not in heads:
                add("minor", "A-02", path, heads["## Consequences"] + 1, f"Consequences without '{h}'")
    if "## Status" in heads:
        i = heads["## Status"] + 1
        while i < len(lines) and not lines[i].strip():
            i += 1
        st = lines[i].strip() if i < len(lines) else ""
        if not any(st.startswith(s) for s in ADR_STATUS):
            add("minor", "A-02", path, i + 1, f"Status '{st[:40]}' not one of {sorted(ADR_STATUS)}")
        if st.startswith("Superseded") and not re.search(r"ADR-\d+", st):
            add("minor", "A-05", path, i + 1, "Superseded without naming the successor ADR")
    if nlines(lines) > ADR_MAX_LINES:
        add("info", "A-06", path, 1, f"{nlines(lines)} lines > {ADR_MAX_LINES} (heuristic)")
    lint_prose(root, path, lines, 1, adr=True)


# ── Prose shared checks ─────────────────────────────────────────────────────────────────
DOC_REF = re.compile(r"`((?:docs|\.cliplin)/[^`\s]+?)`")


FILE_EXT = {"go", "md", "yaml", "yml", "sql", "feature", "json", "sh", "html", "css", "js", "ts", "py", "toml", "mod", "txt", "tmpl", "env"}


def ref_exists(root, r):
    """A backticked path: strip :line, #anchor and a trailing symbol, then look under the repo root."""
    r = r.split("#")[0].split(":")[0].split("(")[0]
    head, _, last = r.rpartition("/")
    if "." in last and last.rsplit(".", 1)[1] not in FILE_EXT:
        r = (head + "/" + last.split(".")[0]) if head else last.split(".")[0]
    return exists(root, r)


def is_framework_ref(line, r):
    """Paths that live in the Cliplin framework's own repository, not in this one."""
    return (os.path.basename(r).startswith("000-cliplin-v2-") and r.startswith("docs/adrs/")) \
        or bool(re.search(r"framework cliplin-v2:\s*`?" + re.escape(r), line))


SECTION_REF = re.compile(r"([A-Za-z0-9_./-]+\.md)`?,?[ \t]+[\"\u201c]([^\"\u201d]{2,})[\"\u201d]")
NUMBERING = re.compile(r"^(?:\d+(?:\.\d+)*[.)]?|[A-Za-z][.)])\s+")
_doc_index = {}
_headings = {}


def resolve_doc(root, p):
    """A cited .md: as written from the repo root, else by basename anywhere under docs/."""
    p = p[2:] if p.startswith("./") else p
    if os.path.isfile(os.path.join(root, p)):
        return [p]
    if not _doc_index:
        for d, _, fs in os.walk(os.path.join(root, "docs")):
            for f in fs:
                _doc_index.setdefault(f, []).append(os.path.relpath(os.path.join(d, f), root))
        _doc_index.setdefault("", [])
    return _doc_index.get(os.path.basename(p), [])


def headings(root, p):
    if p not in _headings:
        hs, in_code = [], False
        for l in read(os.path.join(root, p)):
            if l.startswith("```"):
                in_code = not in_code
            m = None if in_code else re.match(r"^#{1,6}\s+(.*)$", l)
            if m:
                h = re.sub(NUMBERING, "", m.group(1).strip())
                hs.append(h.replace("`", "").replace("*", "").lower())
        body = " ".join(read(os.path.join(root, p)))
        _headings[p] = (hs, re.sub(r"\s+", " ", body.replace("`", "").replace("*", "")).lower())
    return _headings[p]


def check_refs(root, path, ln, l, sev):
    """X-02 (backticked path exists), X-03 (quoted section after a .md path is a heading there)."""
    for ref in DOC_REF.findall(l):
        r = ref.rstrip(".,;:)")
        # Cliplin's own state paths (.cliplin/…) and folder references name places the framework
        # defines, which a repo may not have yet; their absence is not a broken reference.
        if "<" in r or "{" in r or r.startswith(".cliplin/") or r.endswith("/") or is_framework_ref(l, r):
            continue
        if not ref_exists(root, r):
            add(sev, "X-02", path, ln, f"referenced path does not exist: {r}")
    for doc, sec in SECTION_REF.findall(l):
        if is_framework_ref(l, doc):
            continue
        cands = resolve_doc(root, doc)
        if not cands:
            continue
        want = re.sub(NUMBERING, "", sec.strip()).lower()
        flat = re.sub(r"\s+", " ", want.replace("`", "").replace("*", ""))
        # a quote may name a heading or cite the rule's own words; dangling = neither
        if not any(any(want in h for h in headings(root, c)[0]) or flat in headings(root, c)[1] for c in cands):
            add("minor", "X-03", path, ln, f'"{sec}" is neither a heading nor text of {doc}')


def lint_prose(root, path, lines, body, adr=False):
    """X-02/X-03 on prose outside code blocks. An ADR is a dated record: a path it names that does
    not exist (planned, never built) is info."""
    in_code = False
    sev = "info" if adr else "minor"
    for i in range(body, len(lines)):
        l = lines[i]
        if l.startswith("```"):
            in_code = not in_code
        if in_code or l.strip() == "code_refs:":
            continue
        check_refs(root, path, i + 1, l, sev)


def lint_business(root, path):
    lint_prose(root, path, read(os.path.join(root, path)), 0)


# ── context-summary ─────────────────────────────────────────────────────────────────────
def lint_context_summary(root, path):
    lines = read(os.path.join(root, path))
    tops = {re.match(r"^([a-z_]+):", l).group(1): i for i, l in enumerate(lines) if re.match(r"^[a-z_]+:", l)}
    for k in ("concepts", "rules", "last_cycle"):
        if k not in tops:
            add("major", "C-01", path, 1, f"missing top-level '{k}'")
    terms, rids = {}, {}
    for i, l in enumerate(lines):
        if l.lstrip().startswith("#"):
            continue
        m = re.match(r'^\s*-\s*term:\s*"?(.+?)"?\s*$', l)
        if m:
            t = m.group(1).lower()
            if t in terms:
                add("major", "C-02", path, i + 1, f"duplicate term (first at line {terms[t]})")
            terms.setdefault(t, i + 1)
        m = re.match(r'^\s*-\s*id:\s*"?([^"\s]+)"?', l)
        if m:
            if m.group(1) in rids:
                add("major", "C-02", path, i + 1, f"duplicate rule id {m.group(1)} (first at line {rids[m.group(1)]})")
            rids.setdefault(m.group(1), i + 1)
        # Only find_via / source entries are references; a path named inside a definition is prose.
        ref = re.match(r'^\s*(?:-|source:)\s*"?((?:docs|\.cliplin)/[A-Za-z0-9_./-]+\.(?:md|feature|yaml))"?\s*$', l)
        for p in ([ref.group(1)] if ref else []):
            if not exists(root, p):
                add("major", "C-03", path, i + 1, f"find_via/source path does not exist: {p}")
    return set(re.findall(r"docs/[A-Za-z0-9_./-]+\.(?:md|feature)", "\n".join(lines)))


# ── Driver ──────────────────────────────────────────────────────────────────────────────
def collect(root, targets):
    out = []
    for t in targets:
        full = os.path.join(root, t)
        if os.path.isdir(full):
            for d, _, fs in os.walk(full):
                for f in fs:
                    out.append(os.path.relpath(os.path.join(d, f), root))
        elif os.path.isfile(full):
            out.append(t)
        else:
            print(f"warning: {t} not found", file=sys.stderr)
    return sorted(set(out))


def is_spec(f):
    return (f.startswith("docs/") and f.endswith((".feature", ".md"))) or f == ".cliplin/context-summary.yaml"


def changed_since(root, ref):
    """Specs changed since ref: committed (ref...HEAD), staged, unstaged and untracked. Read-only git."""
    def git(*args):
        r = subprocess.run(["git", "-C", root, *args], capture_output=True, text=True)
        if r.returncode != 0:
            sys.exit(f"error: git {' '.join(args)}: {r.stderr.strip()}")
        return [l for l in r.stdout.splitlines() if l.strip()]
    names = set(git("diff", "--name-only", f"{ref}...HEAD"))
    names |= set(git("diff", "--name-only", "HEAD"))
    names |= set(git("ls-files", "--others", "--exclude-standard"))
    return sorted(f for f in names if is_spec(f) and os.path.isfile(os.path.join(root, f)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=".")
    ap.add_argument("--since", metavar="REF")
    ap.add_argument("paths", nargs="*")
    a = ap.parse_args()
    root = os.path.abspath(a.root)
    if a.since:
        targets = changed_since(root, a.since) + list(a.paths)
        print(f"# since {a.since}: {len(targets)} changed spec(s)", file=sys.stderr)
        full = False
        files = collect(root, targets) if targets else []
    else:
        full = not a.paths
        files = collect(root, a.paths or ["docs", ".cliplin/context-summary.yaml"])
    tdr_ids, adr_nums = {}, {}
    governed_all, summary_refs = set(), set()
    for f in files:
        if f.endswith(".feature") and f.startswith("docs/features/"):
            lint_feature(root, f)
        elif f.startswith("docs/tdrs/") and f.endswith(".md"):
            lint_tdr(root, f, tdr_ids)
        elif f.startswith("docs/adrs/") and f.endswith(".md"):
            lint_adr(root, f, adr_nums)
        elif f.startswith("docs/business/") and f.endswith(".md"):
            lint_business(root, f)
        elif f == ".cliplin/context-summary.yaml":
            summary_refs = lint_context_summary(root, f)
    if full:
        for tid, ps in tdr_ids.items():
            if len(ps) > 1:
                add("major", "T-01", ps[1], 1, f"duplicate TDR id '{tid}' (also {ps[0]})")
        for num, ps in adr_nums.items():
            if len(ps) > 1:
                add("major", "A-01", ps[1], 1, f"duplicate ADR number {num} (also {ps[0]})")
        # Orphans: a TDR/ADR no feature governs and no other doc references
        corpus = ""
        for f in files:
            if f.endswith((".feature", ".md", ".yaml")):
                corpus += "\n".join(read(os.path.join(root, f))) + "\n"
        for f in files:
            if f.startswith(("docs/tdrs/", "docs/adrs/")) and f.endswith(".md"):
                base = os.path.basename(f)
                refs = corpus.count(f) + corpus.count(base)
                own = "\n".join(read(os.path.join(root, f)))
                refs -= own.count(f) + own.count(base)
                if refs <= 0:
                    add("info", "X-01", f, 1, "orphan: no feature, TDR, ADR or context-summary references this doc")
        if summary_refs:
            for f in files:
                if f.startswith("docs/tdrs/") and f.endswith(".md") and f not in summary_refs:
                    add("minor", "C-04", f, 1, "TDR not reachable from context-summary.yaml (no find_via/source points at it)")
    rank = {"blocker": 0, "major": 1, "minor": 2, "info": 3}
    findings.sort(key=lambda x: (rank[x[0]], x[1], x[2]))
    for f in findings:
        print("\t".join(f))
    counts = {k: sum(1 for f in findings if f[0] == k) for k in rank}
    print(f"# files={len(files)} " + " ".join(f"{k}={v}" for k, v in counts.items()), file=sys.stderr)


if __name__ == "__main__":
    main()
