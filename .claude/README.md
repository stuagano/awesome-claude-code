# Claude Code Config Starter Kit

A framework for configuring Claude Code (CLI) to reduce cognitive load and maintain organized, persistent project context. Copy this `.claude/` folder to any project for instant access to all resources.

## What's Here

```
.claude/
├── CLAUDE.md                          # Core instructions — the main config
│
├── commands/                          # Slash commands (invoked with /command-name)
│   ├── commit.md                      # Structured commit workflow
│   ├── review.md                      # Code review checklist
│   ├── design-review.md              # Design review workflow
│   ├── land.md                        # Graduate conversations to versioned projects
│   ├── save.md                        # Quick-save context to existing projects
│   ├── project-ideas.md              # Capture and manage idea backlog
│   ├── start.md                       # Interactive project setup
│   ├── pick.md                        # Pull resources into project
│   ├── list-resources.md             # Browse available resources
│   ├── evaluate-repository.md        # Full repository evaluation
│   ├── act.md                         # Action execution
│   ├── add-to-changelog.md           # Update changelogs
│   ├── clean.md                       # Code cleanup
│   ├── context-prime.md              # Prime context from codebase
│   ├── create-hook.md                # Create Claude Code hooks
│   ├── create-jtbd.md                # Jobs-to-be-Done documents
│   ├── create-pr.md                  # Pull request creation
│   ├── create-prd.md                 # Product Requirements Document
│   ├── create-prp.md                 # PR preparation
│   ├── create-pull-request.md        # GitHub CLI PR workflow
│   ├── create-worktrees.md           # Git worktree management
│   ├── debug-error.md                # Error debugging
│   ├── fix-github-issue.md           # GitHub issue resolution
│   ├── husky.md                       # Git hooks setup
│   ├── initref.md                     # Build implementation reference
│   ├── load-llms-txt.md              # Load llms.txt context
│   ├── optimize.md                    # Code optimization
│   ├── plan-feature.md               # Feature planning
│   ├── pr-review.md                  # Pull request review
│   ├── release.md                     # Release/changelog workflow
│   ├── structure-request.md          # Structure user requests
│   ├── testing_plan_integration.md   # Integration test planning
│   ├── todo.md                        # Project todo management
│   ├── update-branch-name.md         # Branch name updates
│   ├── update-docs.md                # Documentation updates
│   ├── databricks-deploy.md          # Databricks deployment
│   ├── databricks-job.md             # Databricks job creation
│   ├── feature-table.md              # Feature table management
│   ├── mlflow-log-model.md           # MLflow model logging
│   └── uc-register-model.md          # Unity Catalog model registration
│
├── preferences/                       # On-demand modes (activated with "mode: X")
│   ├── deep-work.md                   # Maximum focus, minimal chatter
│   ├── exploratory.md                 # Brainstorm and discover
│   └── writing.md                     # Prose and documentation
│
├── templates/                         # Project templates
│   ├── project-status-checklist.md   # Standard format for project status
│   └── claude-md/                     # Domain-specific CLAUDE.md snippets (36)
│       ├── AI-IntelliJ-Plugin.md
│       ├── APX-Databricks-Apps.md
│       ├── AWS-MCP-Server.md
│       ├── Databricks-Full-Stack.md
│       ├── Delta-Live-Tables.md
│       ├── MLflow-Databricks.md
│       ├── Unity-Catalog.md
│       ├── ... (36 domain templates total)
│       └── claude-code-mcp-enhanced.md
│
├── guides/                            # Workflow knowledge guides
│   ├── autonomous-claude-tmux/        # Tmux orchestration & autonomous workflows
│   ├── blogging-platform/             # Blogging platform instructions
│   ├── claude-config-share/           # Config sharing & preference modes
│   └── design-review/                 # Design review methodology
│
└── github-actions/                    # GitHub Actions workflow templates
    ├── claude.yml                     # Base Claude Code action
    ├── ci-failure-auto-fix.yml       # Auto-fix CI failures
    ├── issue-deduplication.yml       # Deduplicate issues
    ├── issue-triage.yml              # Triage incoming issues
    ├── manual-code-analysis.yml      # On-demand code analysis
    ├── pr-review-comprehensive.yml   # Full PR review
    ├── pr-review-filtered-authors.yml # Author-filtered PR review
    ├── pr-review-filtered-paths.yml  # Path-filtered PR review
    └── anthropic-quickstarts.md      # Anthropic quickstart reference
```

## Quick Start

1. Copy `.claude/` into your project root (or `~/.claude/` for global config)
2. Edit `CLAUDE.md`:
   - Set `user = [your name]`
   - Set your timezone
   - Fill in the User Context section
3. Append relevant domain templates from `templates/claude-md/` to your project's `CLAUDE.md`
4. Copy GitHub Actions from `github-actions/` into `.github/workflows/` as needed
5. Create the directories the system expects:
   ```bash
   mkdir -p ~/.claude/{projects.d/archive,transcripts,templates,preferences}
   mkdir -p ~/projects/.ideas
   ```

## Resource Summary

| Type | Count | Location |
|------|-------|----------|
| Slash commands | 40 | `commands/` |
| Preference modes | 3 | `preferences/` |
| CLAUDE.md domain templates | 36 | `templates/claude-md/` |
| Workflow guides | 4 | `guides/` |
| GitHub Actions workflows | 8 | `github-actions/` |

## Key Concepts

### Slash Commands (`/command-name`)
Every `.md` file in `commands/` becomes a slash command. General-purpose commands (commit, review, debug-error, plan-feature, etc.) work in any project. Domain-specific ones (databricks-deploy, mlflow-log-model, etc.) are useful for those stacks. Delete what you don't need.

### Preference Modes
Say "mode: deep-work" and Claude shifts behavior instantly. Modes stack ("mode: writing, deep-work"). Each mode is a simple markdown file describing how Claude should behave.

### Domain Templates (`templates/claude-md/`)
Each file contains domain-specific instructions for a particular stack or tool. Append the relevant ones to your project's `CLAUDE.md` to give Claude specialized knowledge.

### Project Management (`/land`, `/save`, `/project-ideas`)
Three commands form a project lifecycle:

- **`/land`** -- Graduate conversations into versioned project folders with SUMMARY.md files, history snapshots, and transcripts.
- **`/save`** -- Quick-save current session context to an existing project's SUMMARY.md.
- **`/project-ideas`** -- Capture, develop, and manage a backlog of project ideas.

### Workflow Guides (`guides/`)
Multi-step patterns for specific workflows: autonomous tmux sessions, design reviews, blogging, and config sharing.

### GitHub Actions (`github-actions/`)
Ready-to-use GitHub Actions workflows for Claude Code integration: PR reviews, issue triage, CI auto-fix, and code analysis.

### File Safety Rules
Three non-negotiable rules: backup dotfiles before editing, check symlinks before touching files, and never put secrets in config files. These prevent the most common "Claude broke my setup" scenarios.

## Customization

This is a starting point. The most valuable thing here is the framework, not the specific content. Adapt it to how you work:

- **Remove commands** you don't use — fewer is better than overwhelming
- **Append templates** relevant to your stack into your project `CLAUDE.md`
- **Create new preference modes** in `preferences/` for your workflow patterns
- **Add your own commands** in `commands/` — any `.md` file becomes a `/command`
