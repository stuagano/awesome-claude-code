# Awesome Claude Code - Agent Deck

## How It Works

The **Agent Deck** is your home base for managing multiple Claude Code projects. Each project gets tailored slash commands and CLAUDE.md templates installed during setup. You switch between projects from the dashboard.

**Default workflow**: open one Claude session at a time. Use subagents (Task tool) inside the session for parallel work — no extra processes, no wasted tokens.

**Power users**: add `--tmux` for persistent sessions that survive disconnects and support multiple agent windows.

```
You
├── deck                             → Dashboard (home base)
│
├── deck open mirion                 → Claude session in ~/mirion
│   ├── subagent → "fix auth bug"        (Task tool, inline)
│   ├── subagent → "run tests"           (Task tool, inline)
│   └── subagent → "search codebase"     (Task tool, inline)
│
├── deck open guidepoint             → Claude session in ~/guidepoint
│   └── subagents as needed
│
└── deck list                        → project status
```

See [docs/SYSTEM_OVERVIEW.md](docs/SYSTEM_OVERVIEW.md) for the full architecture.

## Quick Start

### Lite Install (no deck/tmux — just global config)

```bash
curl -fsSL https://raw.githubusercontent.com/stuagano/awesome-claude-code/main/install.sh | bash -s -- --lite
```

Installs to `~/.claude/` and works with plain `claude` in any project:
- `/land` — save conversations as versioned projects
- `mode: deep-work` / `exploratory` / `writing` — preference modes
- Safety rules, time awareness, file protection in global CLAUDE.md

### Full Install (deck + tmux orchestrator)

```bash
# Install (one-time)
curl -fsSL https://raw.githubusercontent.com/stuagano/awesome-claude-code/main/install.sh | bash

# Set up projects
deck setup ~/mirion           # guided: detects stack, installs resources
deck setup ~/guidepoint       # same for another project

# Work
deck                          # dashboard (home base)
deck open mirion              # launch Claude in mirion
# ... do work, use subagents for parallelism ...
# exit Claude when done
deck open guidepoint          # switch to another project
```

## Available Domains

| Domain | Resources Available |
|--------|---------------------|
| **Databricks/ML** | MLflow, Unity Catalog, DLT, Feature Engineering, Mosaic AI |
| **Data Engineering** | Pipelines, ETL, data quality |
| **APIs/Backend** | FastAPI, authentication, database patterns |
| **Frontend/Apps** | React, APX apps |
| **DevOps/Infra** | CI/CD, deployment, Docker |

## Core Principles (Always Apply)

### Development Workflow
1. **Understand first** - Read existing code before modifying
2. **Plan if complex** - Outline approach for multi-step tasks
3. **Implement incrementally** - One logical change at a time
4. **Test what you build** - Run tests before considering done
5. **Validate before commit** - Lint, type-check, build should pass

### Keep It Simple
- Don't add features beyond what's asked
- Don't create abstractions for one-time operations
- Don't over-engineer for hypothetical futures
- Three similar lines > premature abstraction

### Code Style
- Type hints for function signatures
- Format with project's formatter (ruff, black, prettier)
- Comments only where logic isn't self-evident
- Delete unused code completely

### Git Practices
- Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
- Never force push to main/master
- Stage specific files (avoid `git add -A`)
- One logical change per commit

## Working with Subagents

When `deck open` launches Claude, use **subagents** (Task tool) for parallel work within the session. This is the recommended approach — it keeps everything in one context and avoids burning tokens on separate processes.

### When to Use Subagents

| Subagent type | For |
|---------------|-----|
| **Explore** | Codebase search, file discovery, architecture understanding |
| **Bash** | Running commands, git operations, builds, tests |
| **Plan** | Designing implementation strategy before coding |
| **general-purpose** | Multi-step research, complex searches |

### How to Orchestrate with Subagents

When given a complex task:

1. **Plan the work** — Break it into steps, use TodoWrite to track
2. **Spawn subagents in parallel** — Multiple Task calls in one message
3. **Implement** — Use results from subagents to make changes
4. **Test** — Spawn a Bash subagent to run tests
5. **Report** — Summarize what was done

### tmux Mode (Power Users)

For long-running work that needs to survive disconnects:

```bash
deck open mirion --tmux       # persistent tmux session
deck spawn mirion             # add another agent window
deck kill mirion              # stop the session
```

When using tmux with Agent Teams enabled, Claude can spawn teammates — separate Claude processes in their own tmux panes. This is powerful but costs more tokens. Use it when you need truly independent, long-running agents.

## Commands

| Command | Purpose |
|---------|---------|
| `/start` | Interactive project setup - "What are we building?" |
| `/pick <resource>` | Pull specific resource into project |
| `/list-resources` | Browse all available resources |
| `/commit` | Structured commit workflow |
| `/review <file>` | Code review checklist |

## Resources

78 resources across three types, installed per-project during setup:

| Type | Location | Count | Purpose |
|------|----------|-------|---------|
| Slash commands | `.claude/commands/` | 31 | Workflow templates (commit, deploy, review, etc.) |
| CLAUDE.md templates | Appended to `CLAUDE.md` | 36 | Domain-specific instructions (MLflow, Databricks, FastAPI, etc.) |
| Workflow guides | Reference docs | 11 | Multi-step patterns (autonomous work, design review, blogging) |

Browse all: `/list-resources` or see `resources/` directory.

See [docs/INSTALL.md](docs/INSTALL.md) for installation details.
