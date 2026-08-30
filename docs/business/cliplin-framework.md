# Cliplin — Spec-First AI-Assisted Development

## The problem it solves

An AI agent without versioned specifications ends up inventing behavior, re-asking questions already answered in earlier conversations, and producing code that passes tests while betraying the original intent. Cliplin starts from Kidlin's Law: *"Describe the problem clearly, and you've already solved half of it."* It applies that literally: **the agent may only act on versioned specifications that live in the repository**. Code is an output of the system, never its source of truth.

## This project's three pillars

Unlike the reference version (which defines five pillars — features, UI-intent, TDR, legacy TS4, ADR/business), this project simplifies to three, consistent with its own scope:

1. **`.feature` (Gherkin)** — what the system must do and why. `docs/features/*.feature`. If a behavior has no `.feature`, it doesn't exist. Each one carries a `@constraints` block (see `docs/tdrs/feature-constraints-format.md`) recording what governs it, what conflicts were detected, and what gaps were accepted — before a single line of code is written.
2. **TDR (Technical Decision Records)** — how it must be implemented correctly. `docs/tdrs/*.md`, YAML frontmatter + rules in prose. They don't describe what to build, they describe how to build it well.
3. **ADR + business documentation** — why each architectural decision was made. `docs/adrs/*.md` and `docs/business/*.md` (this file is one of them). They keep the agent — or a human — from reopening an already-closed decision without new cause.

## What changes relative to the reference version

This project came out of a comparative analysis of prior spec-first AI-development architectures and a real test against GitHub Spec Kit. Three decisions set it apart, all documented in `docs/adrs/000-cliplin-v2-agent-native.md`:

- **No MCP server or vector database** by default — deterministic context discovery via `grep`/`glob`/`read` (`docs/tdrs/deterministic-context-discovery.md`), no embeddings.
- **No CLI or compiled binary** — distributed as a host plugin (Claude Code), plain text and shell scripts only (`docs/tdrs/plugin-packaging.md`).
- **Native, recursive multi-repo coordination** — a single procedure recognizes whether it's working alone or coordinating child repos via `.gitmodules`, with no mode flag (`docs/tdrs/multi-repo-coordination.md`).

## How it's used

A single entry point per work cycle: `cycle-init` (authorship or evolution, auto-detected) → `cycle-run` (implementation, closes with `cycle-validate`). See `docs/tdrs/cycle-commands.md`.

## Notes
- Index in the `business-and-architecture` collection.
- See `docs/adrs/000-cliplin-v2-agent-native.md` for the full decision record and rationale.
