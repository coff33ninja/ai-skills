# AI Skills — Cross-Tool Sync Hub

Central repository for AI agent skill definitions. Edit skills here, then push to all AI tools with one command.

## Structure

```
.
├── sync-skills.ps1        # Push skills + convert to rules
├── skills\                # Source of truth — edit SKILL.md files here
│   ├── anti-cascade-collapse\
│   ├── anti-global-install\
│   ├── anti-library-hallucination\
│   ├── anti-phantom-symbols\
│   ├── anti-premature-termination\
│   ├── anti-rogue-actions\
│   ├── anti-sycophancy\
│   ├── anti-tool-sprawl\
│   ├── break-repetitive-patterns\
│   ├── code-collaborate-qa\
│   ├── dont-kill-tokens\
│   ├── os-awareness\
│   ├── playwright\
│   ├── project-backup-status\
│   ├── requirements-clarify\
│   ├── safe-code-modifications\
│   ├── screenshot\
│   ├── security-best-practices\
│   ├── security-ownership-map\
│   ├── security-threat-model\
│   ├── todo-bootstrap\
│   ├── universal-format-lint\
│   ├── unused-import-implementation\
│   ├── verify-and-cite\
│   └── yeet\
└── README.md
```

## Usage

```powershell
# Sync SKILL.md files to ALL tool skill paths (global/user-profile only)
.\sync-skills.ps1

# Preview without copying
.\sync-skills.ps1 -DryRun

# Sync skills AND generate rule/instruction files for tools with custom formats
.\sync-skills.ps1 -ConvertRules

# Only sync to specific tools (Phase 1 + Phase 2)
.\sync-skills.ps1 -Tool Cursor,Claude,Cline
.\sync-skills.ps1 -ConvertRules -Tool Codex,Copilot -ProjectRoot "C:\MyProject"

# Sync skills to global paths + generate rules into a specific project directory
# Phase 1 still only writes to global paths (~\.tool\skills).
# Phase 2 writes rules to $ProjectRoot\.cursor\rules\ etc.
.\sync-skills.ps1 -ConvertRules -ProjectRoot "C:\MyProject"
```

## What it does

### Phase 1 — Sync SKILL.md directories (global paths only)

Copies skill folders into every AI tool's **global** skill path under `%USERPROFILE%` (e.g. `C:\Users\You\.cursor\skills\`). `-ProjectRoot` has no effect on Phase 1 — it always writes to the same user-profile locations.

| Tool | Path |
|---|---|---|
| Universal / OpenCode | `~\.agents\skills` |
| Claude Code | `~\.claude\skills` |
| Codex CLI | `~\.codex\skills` |
| GitHub Copilot | `~\.copilot\skills` |
| Cursor IDE | `~\.cursor\skills` |
| Gemini CLI | `~\.gemini\skills` |
| Antigravity | `~\.gemini\antigravity\skills` |
| Kiro | `~\.kiro\skills` |
| Windsurf | `~\.codeium\windsurf\skills` |
| Continue | `~\.continue\skills` |
| Augment | `~\.augment\skills` |
| Tabnine | `~\.tabnine\agent\skills` |
| Cline | `~\.cline\skills` |
| Roo Code | `~\.roo\skills` |

### Phase 2 — Convert to rules/instructions (`-ConvertRules`)

Generates tool-specific rule and instruction files from SKILL.md content. Project-root outputs only when `-ProjectRoot` is specified (Cursor, Windsurf, and Copilot skip with a warning otherwise). Phase 2 does not run in `-DryRun` mode.

| Tool | Format | Global output | Project output |
|---|---|---|---|
| **Codex CLI** | `AGENTS.md` | `~\.codex\AGENTS.md` | `$ProjectRoot\AGENTS.md` |
| **GitHub Copilot** | `copilot-instructions.md` | — | `$ProjectRoot\.github\copilot-instructions.md` |
| **Cursor IDE** | `.mdc` rules (one per skill) | — | `$ProjectRoot\.cursor\rules\skill-*.mdc` |
| **Windsurf** | `.md` rules (one per skill) | — | `$ProjectRoot\.windsurf\rules\skill-*.md` |

### Tool filtering

The `-Tool` parameter limits both phases to specific tools. Accepts: `Agents`, `Claude`, `Codex`, `Copilot`, `Cursor`, `Gemini`, `Antigravity`, `Kiro`, `Windsurf`, `Continue`, `Augment`, `Tabnine`, `Cline`, `RooCode`.

- **Omitted** (default): all tools
- **Specified**: only matching tools get Phase 1 sync + Phase 2 rule generation
- **`-DryRun`**: Phase 1 shows what would be synced; Phase 2 is skipped entirely
- Examples: `-Tool Cursor` (syncs `~\.cursor\skills\` + generates `.cursor\rules\`),
  `-Tool Cursor,Claude,Cline` (three tools),
  `-Tool Codex,Copilot -ConvertRules -ProjectRoot "C:\Project"` (project rules for Codex + Copilot only)

## Workflow

1. Add/edit a `SKILL.md` in `skills\<name>\`
2. Run `.\sync-skills.ps1` — synced to all global tool paths.
   Use `-Tool Cursor,Copilot` to target specific tools instead. Add `-ConvertRules` to also generate rule files. Add `-ProjectRoot <path>` to write project-level rules into a specific project directory.
3. All AI tools pick it up on next launch

## Skill Format

Each skill is a folder with a `SKILL.md` file containing YAML frontmatter:

```yaml
---
name: skill-name
description: Semantic trigger for AI tools to auto-load this skill
---
```

The `name` and `description` are the primary match keys tools use to decide when to load a skill. Optional resource directories (`scripts/`, `references/`, `assets/`) are bundled alongside and loaded on demand.

## Skill Catalog

| Skill | Description | Scripts | Assets | Refs |
|---|---|---|---|---|
| **anti-cascade-collapse** | Prevents order-gap hallucination — re-verifies assumptions at each step to avoid cascade failure | | | |
| **anti-global-install** | Never installs tools globally; uses project-local environments (venv, node_modules, etc.) | | | |
| **anti-library-hallucination** | Prevents suggesting non-existent packages, fabricated libs, typosquatting risks | | | |
| **anti-phantom-symbols** | Prevents invented APIs, imports, methods — verifies symbols against actual codebase | | | |
| **anti-premature-termination** | Enforces explicit completion criteria, verification steps before declaring done | | | |
| **anti-rogue-actions** | Prevents absurd/destructive outcomes; enforces bounds, permissions, sanity checks | | | |
| **anti-sycophancy** | Prevents compensatory sycophancy, fix loops — hard resets after 2+ failed corrections | | | |
| **anti-tool-sprawl** | Prevents over-tooling, spam, bloat; lean selection + progress detection | | | |
| **break-repetitive-patterns** | Detects repetitive questions; breaks trained logic with proactive alternatives | | | |
| **playwright** | Browser automation: navigation, forms, screenshots, data extraction via CLI | ✅ | ✅ | ✅ |
| **project-backup-status** | Timestamped backups + repo status check before risky edits | | | |
| **requirements-clarify** | Structured Q&A before ambiguous tasks — one question at a time, multiple choice, assumption surfacing, confirmation step | | | |
| **code-collaborate-qa** | Code-focused Q&A for code review, bug diagnosis, and implementation suggestions — developer intent, reproduction steps, trade-offs, confirmation gate | | | |
| **dont-kill-tokens** | Token-efficient tool use — minimal reads, batched calls, zero comments, no postambles, one-word answers when sufficient | | | |
| **os-awareness** | OS detection and session memory — prevents Linux-isms on Windows, wrong path separators, incorrect shebangs, incompatible shell syntax | | | |
| **safe-code-modifications** | Never removes imports/items without verifying usage across modules | | | |
| **screenshot** | Cross-platform desktop screenshot capture (macOS/Linux/Windows) | ✅ | ✅ | |
| **security-best-practices** | Language/framework security reviews and secure-by-default coding | | | ✅ |
| **security-ownership-map** | Git-based security ownership topology, bus factor, CSV/JSON export | ✅ | | ✅ |
| **security-threat-model** | Repository-grounded threat modeling with mitigations | | | ✅ |
| **todo-bootstrap** | Creates/refreshes Markdown TODO checklists grounded in actual codebase | | | |
| **universal-format-lint** | Formatter + lint-fixer per file type (Python, JS/TS, Markdown, YAML, PS1, sh) | | | |
| **unused-import-implementation** | Infers intent and implements missing use instead of deleting unused imports | | | |
| **verify-and-cite** | Reduces hallucinations via verification, sourcing, uncertainty expression | | | |
| **yeet** | Stage, commit, push, and open a draft PR in one flow via `gh` | | ✅ | |

---

## ⚠️ The Fine Print — Read or Regret

### Skills are hit-and-run

These skills are loaded **when the AI deems them relevant**, not every time. Context windows are finite. If your agent is deep in a 100k-token session debugging a memory leak, it may not also load the anti-hallucination skill — even if you're hallucinating. This is called a **context miss**, and it's a feature of every tool, not a bug. Re-prompt if needed.

### Did the AI actually register them?

Some agents silently skip skills. Some say they loaded them but didn't. The only way to know is to **ask directly**. If you're unsure whether the AI is following these guardrails, say:

> *"List every skill you have registered and whether each one is active right now."*

If it can't name them, they're not loaded. Prompt again, or check the skill files exist in your tool's skills directory.

### Why these skills exist

This repository was born from **blood, sweat, and hallucinations** — watching AI agents confidently fabricate library names, invent API endpoints, install packages globally, declare tasks complete without doing them, and spiral into sycophantic agreement loops. Each `anti-*` skill here exists because a real production incident made it necessary.

Not all agents play nice. Not all skills stick. But when they *do* load, they save hours of debugging garbage output.

---

**Maintained by [coff33ninja](https://github.com/coff33ninja)** — because trusting AI without guardrails is just organized gambling.

*These skills may or may not load. Your mileage will vary. The AI giveth and the AI taketh away.*
