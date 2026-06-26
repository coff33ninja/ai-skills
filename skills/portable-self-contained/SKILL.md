---
name: portable-self-contained
description: Keeps all dependencies, SDKs, virtual environments, and tooling inside the project directory. Prevents polluting the OS drive (especially C: with <30% free) by using project-local installs. Always checks disk space and documents the setup.
---

# Portable Self-Contained Project Skill

## Problem it solves

Projects install SDKs, venvs, node_modules, and build artifacts on the system drive (C:) by default. Users with multiple drives or low C: capacity end up with a clogged OS drive. Environments are not reproducible because they depend on global state. Moving or sharing the project breaks everything.

## Protocol

### 1. Before any install or setup

**Check disk space** on the target drive:

```powershell
$drive = (Get-Location).Drive.Name + ":"
$free = (Get-PSDrive -Name (Get-Location).Drive.Name).Free / 1GB
if ($free -lt 10) { Write-Warning "Only $free GB free on $drive — consider alternate install location" }
```

If the system drive (C:) has under 30% free or under 10 GB free, prompt the user to choose an install drive. Do not silently use C:.

### 2. Python projects

**Use `uv`** — not system pip or global Python:

```
uv venv .venv                  # project-local virtual env
uv pip install -e .            # or uv sync with pyproject.toml
uv add <package>               # adds to pyproject.toml
```

- Always create `.venv/` inside the project root
- Always use `pyproject.toml` (not `requirements.txt` unless required by a tool)
- Add `.venv/` to `.gitignore`
- Never use `pip install --user` or system-level Python packages
- If `uv` is not installed, offer to install it locally: `powershell -c "irm https://astral.sh/uv/install.ps1 | iex"`

### 3. Flutter / Dart projects

- Place Flutter SDK in a project-adjacent directory (e.g. `../flutter/` or `tools/flutter/`) — never in `C:\Program Files` or global paths
- Use `fvm` (Flutter Version Management) with project-local config via `.fvm/flutter_sdk`
- Set `FLUTTER_ROOT` or `FVM_ROOT` to the local SDK path, not a global install
- Document the SDK path in a `setup.ps1` or `Makefile`

### 4. Node.js / npm projects

- `node_modules/` lives in the project — this is the default behavior
- For global tools (TypeScript, Vite, etc.), use `npx` or add as devDependencies, never `npm install -g`
- If `npm install -g` is unavoidable, warn the user and offer `--prefix` to point to a project-local location
- Use `.npmrc` with `prefix=./.npm-global` for project-local global installs if needed
- Add `node_modules/` and `.npm-global/` to `.gitignore`

### 5. Rust projects

- `cargo` already uses project-local `target/` — keep it that way
- For tools installed via `cargo install`, use `--root ./tools` to keep binaries in the project
- Add `tools/` to `.gitignore`

### 6. Scripts go in a scripts/ folder

Every script (setup, build, deploy, utility) goes in a top-level `scripts/` directory:

```
project/
├── scripts/
│   ├── setup.ps1          # environment setup
│   ├── build.ps1          # build project
│   ├── lint.ps1           # run linters
│   ├── test.ps1           # run tests
│   ├── deploy.ps1         # deploy artifact
│   └── clean.ps1          # clean artifacts
├── src/
├── tests/
└── README.md
```

Rules:
- No scripts in the project root — only `scripts/`, `src/`, `docs/`, `tests/` and config files at root
- Use `scripts/` for batch files, PowerShell scripts, shell scripts, Python utility scripts
- Document each script's purpose in the README or a `scripts/README.md`
- Use descriptive filenames: `setup.ps1` not `doStuff.ps1`
- For single-script projects, still use `scripts/` — e.g. `scripts/build.ps1`

### 7. General rules

| Resource | Default (bad) | Portable (good) |
|----------|---------------|-----------------|
| Python venv | `~/.virtualenvs/` or system | `./.venv/` |
| Python packages | `pip install --user` | `uv sync` in `./.venv/` |
| Flutter SDK | `C:\tools\flutter` | `./tools/flutter/` or adjacent |
| npm global bins | `%APPDATA%\npm` | `npx` or `./node_modules/.bin/` |
| Cargo installs | `~/.cargo/bin/` | `./tools/bin/` with `--root` |
| Build artifacts | `~/build/` | `./build/` or `./target/` |

### 7. Documentation and setup script

Always create or update:

- **`SETUP.md`** — Documents the exact steps to set up the environment from scratch, including:
  - Which tools need to be installed (with install commands)
  - Where each SDK/environment lives (relative to project root)
  - How to activate/use the environment
  - Why each choice was made (portability, drive space, reproducibility)
- **`setup.ps1`** (or `setup.sh` for non-Windows) — Automates the full setup:
  - Checks disk space
  - Installs required tools (uv, fvm, etc.) if missing
  - Creates project-local environments
  - Verifies everything works
  - Reports status at each step

### 8. When working with existing projects

Do not restructure an existing project's environment layout unless the user asks. If the project already uses system-level installs, note it and offer to migrate — do not do it automatically.

## Detection triggers

Activate when:
- Setting up a new project or environment
- Installing SDKs, runtimes, or package managers
- Creating setup scripts or documentation
- User mentions drive space, portability, or "keep it in the project"

## When NOT to use
- Docker containers (they are already isolated)
- CI/CD runners (ephemeral environments)
- User explicitly says to use system-wide installs


## Cross-references

- **anti-global-install** — Direct overlap on avoiding global installs. portable-self-contained adds disk-space checks, scripts/ folder conventions, setup docs, and multi-language SDK handling.
- **os-awareness** — OS-aware paths and commands are required for correct project-local environment setup across Windows/Linux/macOS.


- **audit-project** — Run an audit to detect environment portability violations (global installs, hardcoded paths, missing setup docs).

- **toolchain-fallback** — Toolchain detection and fallback install scripts must follow the scripts/ folder convention defined in portable-self-contained section 6.
- **playwright** — The Playwright CLI skill previously bundled its wrapper script. Per section 6, tooling scripts should live in the project's `scripts/` or `tools/` directory and be installed on-demand (via npx), not copied with the skill.
- **project-scripts** — Complements the scripts/ folder convention by discovering and cataloging scripts wherever they are. portable-self-contained prescribes where scripts should go; project-scripts finds what actually exists.
- **anti-global-install** — The portability checker detects global installs that violate project-local rules.
- **skill-loader** — Apply the capped selection policy when deciding which environment-related skills should also be active for portability assessments.

## Bundled portability checker

A bundled script at `scripts/check-portability.ps1` (PowerShell) audits a project's environment portability:

```powershell
.\scripts\check-portability.ps1 -ProjectPath ".\"
```

Checks: drive free space, `.venv/` existence, `node_modules/` (if package.json present), `scripts/` directory, SETUP.md, `.gitignore` coverage. Exits with non-zero on issues.

To use as a project-local tool:

```powershell
cp <skill-path>/portable-self-contained/scripts/check-portability.ps1 .ai_scripts/
.ai_scripts\check-portability.ps1 -ProjectPath "."
```
