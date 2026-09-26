---
tdr: "1.0"
id: "installation"
title: "Installation — Claude Code and Codex Local Marketplaces"
summary: "The repository exposes host-specific marketplace manifests over one shared plugin payload. Claude Code is verified end-to-end; the Codex package is schema-validated and uses Codex's native marketplace commands."
---

# rules

## Host selection

- Claude Code: `bash install-claude.sh --marketplace`, or the legacy-compatible
  `bash install.sh --global` skills-directory fallback.
- Codex: `bash install-codex.sh --marketplace`.
- Project briefing only: pass a project path to the corresponding installer. Claude
  writes/merges `.claude/CLAUDE.md`; Codex writes/merges `AGENTS.md`.
- Both marketplaces install the canonical payload at `plugins/cliplin-v2`; never
  fork or copy the skills by host.

## What's actually verified now (MUST trust this over earlier revisions of this TDR)

Two earlier revisions of this TDR were wrong in ways only caught by real testing: hooks inline in `plugin.json` (silently failed), then project-scope skills-directory install (blocked by an untested workspace-trust dialog). This revision reflects the path that was run for real and confirmed:

```bash
claude plugin marketplace add /path/to/cliplin-v2   # or a relative ./path; bare "." is rejected
claude plugin install cliplin-v2@cliplin
claude plugin list   # shows cliplin-v2@cliplin — Status: ✔ enabled
```

## Repository layout (MUST match — this is why it works)

The marketplace and the plugin are two different things at two different paths, per Claude Code's documented local-marketplace convention:

```
cliplin-v2/                          # the marketplace
├── .claude-plugin/
│   └── marketplace.json             # {"name": "cliplin", "owner": {...}, "plugins": [{"name": "cliplin-v2", "source": "./plugins/cliplin-v2", ...}]}
└── plugins/
    └── cliplin-v2/                  # the plugin itself — this is what install.sh also copies
        ├── .claude-plugin/plugin.json
        ├── skills/
        ├── agents/
        ├── hooks/
        │   ├── hooks.json
        │   └── session-start.sh
        └── templates/
```

An earlier revision had `.claude-plugin/plugin.json`, `skills/`, `agents/`, `hooks/`, `templates/` directly at the repo root — that only works for `--plugin-dir` testing or a skills-directory install, not for a marketplace, where the marketplace root and each plugin's root must be separate directories.

## Known collision to avoid (MUST follow)

Do not have both a marketplace-installed copy (`cliplin-v2@cliplin`) and a skills-directory copy (`~/.claude/skills/cliplin-v2/`) active at once. `plugin.json`'s `name` field is `"cliplin"` (the namespace), and Claude Code resolves the conflict by giving the already-installed plugin precedence — the skills-directory copy silently fails to load with `Status: ✘ Not loaded — the name "cliplin" is already taken`. Confirmed via `claude plugin list` during this project's own install debugging. Pick one path per machine.

## Remaining paths, in order of what to try

1. **Local marketplace** (above) — verified working, no publishing required, works today.
2. **`install.sh --global`** (`~/.claude/skills/cliplin-v2/`) — verified file layout, but do not run this if the marketplace path is already installed (see collision note above). Useful for hosts where marketplace commands aren't available.
3. **`claude --plugin-dir plugins/cliplin-v2`** — fastest loop for iterating on the plugin itself during development; loads for one session only, `/reload-plugins` picks up edits.
4. **Public marketplace** (`.claude-plugin/marketplace.json`'s current `source: "./plugins/cliplin-v2"` is a relative path, valid for local/git-hosted use; once this repo has a real remote, update to a `github`/`url` source per Claude Code's marketplace schema for others to install without cloning first) — not yet needed for local use, this repo has no remote configured.

## Debugging checklist (kept from the prior revision, still accurate)

1. Validate `marketplace.json` and each plugin's `plugin.json` independently as JSON.
2. `claude plugin marketplace list` — confirm the marketplace itself registered.
3. `claude plugin list` — ground truth on install status, not inference from a missing banner.
4. `claude plugin uninstall <name>@<marketplace>` to remove a stale/broken entry before retrying — do this rather than leaving broken entries to accumulate.

code_refs:
  - "install.sh"
  - ".claude-plugin/marketplace.json"
  - "plugins/cliplin-v2/.claude-plugin/plugin.json"
  - "plugins/cliplin-v2/hooks/hooks.json"
