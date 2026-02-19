# Claude Code Config Starter Kit

A framework for configuring Claude Code (CLI) to reduce cognitive load and maintain organized, persistent project context.

## What's Here

```
.
|- CLAUDE.md                          # Core instructions -- the main config
|- commands/                          # Custom skills (invoked with /command-name)
|   |- land.md                        # Graduate conversations to versioned projects
|   |- save.md                        # Quick-save context to existing projects
|   |- project-ideas.md              # Capture and manage a project idea backlog
|- preferences/                       # On-demand modes (activated with "mode: X")
|   |- deep-work.md                   # Maximum focus, minimal chatter
|   |- exploratory.md                 # Brainstorm and discover
|   |- writing.md                     # Prose and documentation
|- templates/
    |- project-status-checklist.md    # Standard format for project status display
```

## Installation

1. Copy files into your `~/.claude/` directory, preserving the folder structure
2. Edit `CLAUDE.md`:
   - Set `user = [your name]`
   - Set your timezone
   - Fill in the User Context section
3. Set up any services referenced in skills (task manager, etc.)
4. Create the directories the system expects:
   ```bash
   mkdir -p ~/.claude/{projects.d/archive,transcripts,templates,preferences}
   mkdir -p ~/projects/.ideas
   ```

## Key Concepts

### Preference Modes
Say "mode: deep-work" and Claude shifts behavior instantly. Modes stack ("mode: writing, deep-work"). Each mode is a simple markdown file describing how Claude should behave.

### Project Management (`/land`, `/save`, `/project-ideas`)
Three commands form a project lifecycle:

- **`/land`** -- Graduate conversations into versioned project folders with SUMMARY.md files, history snapshots, and transcripts. A hot index (`~/.claude/projects.d/`) tracks what you're actively working on with a 30-day TTL.
- **`/save`** -- Quick-save current session context to an existing project's SUMMARY.md. Lightweight checkpoint without creating new folders or transcripts.
- **`/project-ideas`** -- Capture, develop, and manage a backlog of project ideas. Ideas live in `~/projects/.ideas/` and can be graduated to full `/land` projects when ready. Actions: `add`, `list`, `develop`, `land`, `prune`.

### File Safety Rules
Three non-negotiable rules: backup dotfiles before editing, check symlinks before touching files, and never put secrets in config files. These prevent the most common "Claude broke my setup" scenarios.

## Customization

This is a starting point. The most valuable thing here is the framework, not the specific content. Adapt it to how you work.
