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
│   ├── adr-and-documentation\
│   ├── audit-project\
│   ├── break-repetitive-patterns\
│   ├── code-collaborate-qa\
│   ├── code-review\
│   ├── debugging-and-error-recovery\
│   ├── detect-utf8\
│   ├── dont-kill-tokens\
│   ├── follow-existing-patterns\
│   ├── git-workflow-conventional-commits\
│   ├── incremental-implementation\
│   ├── no-dead-code-removal\
│   ├── os-awareness\
│   ├── playwright\
│   ├── portable-self-contained\
│   ├── project-backup-status\
│   ├── project-scripts\
│   ├── release-changelog\
│   ├── requirements-clarify\
│   ├── safe-code-modifications\
│   ├── screenshot\
│   ├── security-best-practices\
│   ├── security-ownership-map\
│   ├── security-threat-model\
│   ├── self-validate\
│   ├── skill-loader\
│   ├── spec-driven-development\
│   ├── test-driven-development\
│   ├── todo-bootstrap\
│   ├── toolchain-fallback\
│   ├── universal-format-lint\
│   ├── unused-import-implementation\
│   ├── uv\
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
|---|---|
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

Generates tool-specific rule and instruction files from SKILL.md content. When `-ProjectRoot` is specified, files go to the project directory; otherwise they fall back to global user-profile paths. Phase 2 does not run in `-DryRun` mode.

| Tool | Format | Global output (no `-ProjectRoot`) | Project output (with `-ProjectRoot`) |
|---|---|---|---|
| **Codex CLI** | `AGENTS.md` | `~\.codex\AGENTS.md` | `$ProjectRoot\AGENTS.md` |
| **GitHub Copilot** | `copilot-instructions.md` | `~\.copilot\copilot-instructions.md` | `$ProjectRoot\.github\copilot-instructions.md` |
| **Cursor IDE** | `.mdc` rules (one per skill) | `~\.cursor\rules\skill-*.mdc` | `$ProjectRoot\.cursor\rules\skill-*.mdc` |
| **Windsurf** | `.md` rules (one per skill) | `~\.codeium\windsurf\rules\skill-*.md` | `$ProjectRoot\.windsurf\rules\skill-*.md` |

### Tool filtering

The `-Tool` parameter limits both phases to specific tools. Accepts: `Agents`, `Claude`, `Codex`, `Copilot`, `Cursor`, `Gemini`, `Antigravity`, `Kiro`, `Windsurf`, `Continue`, `Augment`, `Tabnine`, `Cline`, `RooCode`.

- **Omitted** (default): all tools
- **Specified**: only matching tools get Phase 1 sync + Phase 2 rule generation
- **`-DryRun`**: Phase 1 shows what would be synced; Phase 2 is skipped entirely
- **`-ProjectRoot`**: When set, Phase 2 writes tool rules to the project directory; otherwise rules go to global user-profile paths (`~\.cursor\rules\`, `~\.codeium\windsurf\rules\`, etc.)
- Examples: `-Tool Cursor` (syncs to `~\.cursor\skills\` + generates rules in `~\.cursor\rules\`),
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
| **anti-cascade-collapse** | Prevents order-gap hallucination — where the model detects a false premise when asked directly but misses it when embedded in a complex multi-step task. Enforces re-verification of assumptions at each step. | ✅ | | |
| **anti-global-install** | Never install tools/packages into global system locations. Always detect and use the project's existing environment (venv, node_modules, target, vendor, etc.) or create a project-local one. Applies to all languages. | ✅ | | |
| **anti-library-hallucination** | Prevents suggesting non-existent packages, fabricated library names, and invalid version pins. Also guards against typosquatting and slopsquatting risks. | ✅ | | |
| **anti-phantom-symbols** | Prevents invented APIs, imports, methods, and class members that don't exist. Verifies every symbol against the project's actual codebase and framework docs before writing it. | ✅ | | |
| **anti-premature-termination** | Prevents declaring a task complete before it's actually done. Enforces explicit completion criteria, verification steps, and receipt-based confirmation. | ✅ | | |
| **anti-rogue-actions** | Prevents valid-looking API calls with absurd or destructive outcomes. Enforces business logic guardrails, parameter bounds, permission boundaries, and pre-execution sanity checks. | ✅ | | |
| **anti-sycophancy** | Prevents Compensatory Sycophancy, Acknowledgment-Action Gap, and Infinite Fix Loops. Enforces hard resets after 2+ failed corrections. Ensures listening over validating. | ✅ | | |
| **anti-tool-sprawl** | Prevents over-tooling, tool spam, context bloat, and convergence failure. Enforces lean tool selection, deduplication, step limits, and progress detection. | ✅ | | |
| **adr-and-documentation** | Enforces Architecture Decision Records (ADRs) and keeps docs in sync with code. Prevents "why did we do it this way?" six months later and stale documentation. | | | |
| **audit-project** | Runs a systematic audit of a project — checking dependency health, security vulnerabilities, config integrity, code consistency, disk usage, and environment portability. Produces a report with findings prioritized by severity. | ✅ | | |
| **break-repetitive-patterns** | Detects when user is asking repetitive questions and helps break out of trained logic patterns by triggering proactive research and alternative approaches. | ✅ | | |
| **code-collaborate-qa** | Guides code-focused Q&A for code review, bug diagnosis, and implementation suggestions. Asks about developer intent, reproduction steps, constraints, and trade-offs before writing code or giving feedback. Use when the user asks for code review, bug fix help, refactoring suggestions, performance improvements, or implementation advice. Not for requirements gathering (use requirements-clarify instead). | ✅ | | |
| **code-review** | Enforces systematic multi-axis code review (correctness, readability, architecture, security, performance) with severity ratings and actionable findings. Use before merging, before declaring done, or when explicitly asked to review code. Unlike code-collaborate-qa (conversational Q&A), this is a structured process with checklists. | | | |
| **debugging-and-error-recovery** | Enforces structured debugging workflow — reproduce, localize, reduce, fix, guard. No fix until root cause is identified with file:line evidence. One-change-at-a-time hypothesis testing. Prevents surface-level fixes and random guessing. | | | |
| **detect-utf8** | Detects whether the terminal, console, or device supports UTF-8 encoding. Checks code page, .NET encoding defaults, environment locale, and verifies with a round-trip test of Unicode characters. | ✅ | | |
| **dont-kill-tokens** | Enforces token-efficient tool use. Prevents wasteful reads, redundant searches, unnecessary output, and bloated responses. Activates on all tasks to minimize context consumption. | ✅ | | |
| **follow-existing-patterns** | Enforces that all new code, docs, and config match the existing codebase conventions, structure, and style — preventing inconsistent implementations that get reworked each session. | ✅ | | |
| **git-workflow-conventional-commits** | Enforces standardized git workflow — conventional commits, atomic commits (one concern per), branch naming, PR standards, and commit message formatting. Prevents inconsistent history and unreadable git log. | | | |
| **incremental-implementation** | Breaks changes into thin vertical slices. Start with a minimal end-to-end slice, then add layers. Prevents massive diffs that are impossible to review and merge conflicts from long-lived branches. | | | |
| **no-dead-code-removal** | Never remove dead code you added. Refactor it into something useful instead. Deletion is not an option for code you wrote in this session. | ✅ | | |
| **os-awareness** | Forces the AI to detect, confirm, and remember the host operating system before any command execution, file operation, or path construction. Prevents Linux-isms on Windows, wrong path separators, incorrect shebangs, and incompatible shell syntax. | ✅ | | |
| **playwright** | Use when the task requires automating a real browser from the terminal (navigation, form filling, snapshots, screenshots, data extraction, UI-flow debugging) via `playwright-cli` invoked through npx in the project directory. | | | |
| **portable-self-contained** | Keeps all dependencies, SDKs, virtual environments, and tooling inside the project directory. Prevents polluting the OS drive (especially C: with <30% free) by using project-local installs. Always checks disk space and documents the setup. | ✅ | | |
| **project-backup-status** | Create a timestamped project backup and inspect the repo's current status before making changes. Use when starting work in any project, before risky edits or refactors, when the user asks to back up or safeguard a codebase, or when continuity matters and code tools should read TODO/status docs before acting. | ✅ | | |
| **project-scripts** | Discovers, catalogs, and manages project scripts (install, download, build, setup, clean). Scans conventional script locations, detects AI-generated and user-created scripts, and generates missing standard scripts. Use when setting up a new project, looking for available scripts, or ensuring script consistency. | | | |
| **release-changelog** | Standardized release workflow — version bump, Keep a Changelog formatting, and CI/CD pipeline integration with auto-tagging and release automation. Works for any language (Python, Rust, Node, Go, etc.). Use when the user asks to cut a release, bump version, update changelog, or prepare release notes. | | | |
| **requirements-clarify** | Runs a structured Q&A session before starting any ambiguous task. Asks one question at a time using multiple choice first, surfaces assumptions, confirms understanding. Use when the user gives vague requests, incomplete specs, conflicting goals, missing context, or says anything like "build this", "make it work", "fix it", "implement feature", "refactor this", "add functionality", or any task where you need to clarify scope, constraints, or requirements before starting work. Not for simple well-defined tasks. | ✅ | | |
| **safe-code-modifications** | Ensures code modifications follow safe practices - never remove imports/items without verifying usage, check if truly obsolete, and confirm usage by other modules before removal. | ✅ | | |
| **screenshot** | Use when the user explicitly asks for a desktop or system screenshot (full screen, specific app or window, or a pixel region), or when tool-specific capture capabilities are unavailable and an OS-level capture is needed. | ✅ | | |
| **security-best-practices** | Perform language and framework specific security best-practice reviews and suggest improvements. Trigger only when the user explicitly requests security best practices guidance, a security review/report, or secure-by-default coding help. Trigger only for supported languages (python, javascript/typescript, go). Do not trigger for general code review, debugging, or non-security tasks. | ✅ | | ✅ |
| **security-ownership-map** | Analyze git repositories to build a security ownership topology (people-to-file), compute bus factor and sensitive-code ownership, and export CSV/JSON for graph databases and visualization. Trigger only when the user explicitly wants a security-oriented ownership or bus-factor analysis grounded in git history (for example: orphaned sensitive code, security maintainers, CODEOWNERS reality checks for risk, sensitive hotspots, or ownership clusters). Do not trigger for general maintainer lists or non-security ownership questions. | ✅ | | ✅ |
| **security-threat-model** | Repository-grounded threat modeling that enumerates trust boundaries, assets, attacker capabilities, abuse paths, and mitigations, and writes a concise Markdown threat model. Trigger only when the user explicitly asks to threat model a codebase or path, enumerate threats/abuse paths, or perform AppSec threat modeling. Do not trigger for general architecture summaries, code review, or non-security design work. | ✅ | | ✅ |
| **self-validate** | After any batch of changes (edits, skill updates, cross-references, docs), runs systematic validation to catch inconsistencies, missing references, broken links, and syntax errors before declaring done. Prevents the need for follow-up corrections. | ✅ | | |
| **skill-loader** | When a skill is loaded, selectively loads the most relevant direct cross-references with strict caps. Preserves core operating discipline without letting cross-references cascade into context bloat. | | | |
| **spec-driven-development** | Forces writing a specification before any code changes. Defines goals, inputs/outputs, constraints, edge cases, and acceptance criteria before implementation. Use when starting any non-trivial feature, refactor, or bug fix. Prevents solving the wrong problem. | | | |
| **test-driven-development** | Enforces RED-GREEN-REFACTOR cycle — write a failing test first, write minimal code to pass, then refactor. Use when implementing new features, fixing bugs, or adding regression coverage. Prevents untestable code and false confidence from untested changes. | | | |
| **todo-bootstrap** | Create or refresh a project TODO checklist using Markdown checkboxes and keep it current as work progresses. Use when a repo has no TODO tracker, when the user asks for a backlog, roadmap, status checklist, or progress board, or when docs exist but do not yet include a canonical checkbox-based task list. | ✅ | | |
| **toolchain-fallback** | Detects available build toolchains (MSYS2, Zig, GCC, Clang, Visual Studio) and falls back to a working alternative when none are found. Any implementation scripts follow the project's scripts/ folder convention. | ✅ | | |
| **universal-format-lint** | Run language-appropriate formatter and lint-fix commands for changed files. Use when the user asks to format, lint, auto-fix, or clean code style across Python, JavaScript/TypeScript, Markdown, YAML/JSON, PowerShell, shell scripts, and similar files. | ✅ | | |
| **unused-import-implementation** | Diagnose and resolve newly added but unused imports by inferring intent from surrounding code and implementing the missing use case. Use when linting or review reports an unused import and the import appears intentional or recent, and the goal is to complete behavior rather than remove code. | ✅ | | |
| **uv** | Use when installing Python tooling, managing Python environments, running Python scripts, or managing Python dependencies. Use command `uv` for all Python operations instead of `pip` or `python -m venv`. | ✅ | | |
| **verify-and-cite** | Reduces hallucinations by requiring verification, sourcing claims, and expressing appropriate uncertainty when information cannot be confirmed. | ✅ | | |
| **yeet** | Use only when the user explicitly asks to stage, commit, push, and open a GitHub pull request in one flow using the GitHub CLI (`gh`). | ✅ | | |

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
