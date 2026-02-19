# Claude Code Config Starter Kit

A framework for configuring Claude Code (CLI) to reduce cognitive load and maintain organized, persistent project context.

## What's Here

```
.
|- CLAUDE.md                          # Core instructions -- the main config
|- commands/                          # Custom skills (invoked with /command-name)
|   |- land.md                        # Graduate conversations to versioned projects
|   |- daily-review.md                # Morning briefing template
|   |- notify.md                      # Slack notification webhook
|   |- weekly-report.md               # Weekly metrics aggregation
|- preferences/                       # On-demand modes (activated with "mode: X")
|   |- deep-work.md                   # Maximum focus, minimal chatter
|   |- exploratory.md                 # Brainstorm and discover
|   |- writing.md                     # Prose and documentation
|   |- music.md                       # Playlist preferences (customize to taste)
|- templates/
    |- project-status-checklist.md    # Standard format for project status display
```

## Installation

1. Copy files into your `~/.claude/` directory, preserving the folder structure
2. Edit `CLAUDE.md`:
   - Set `user = [your name]`
   - Set your timezone
   - Fill in the User Context section
   - Update the 1Password account in Rule 3 (or remove if you don't use 1Password)
3. Customize `preferences/music.md` to your taste
4. Set up any services referenced in skills (Slack webhook, task manager, etc.)
5. Create the directories the system expects:
   ```bash
   mkdir -p ~/.claude/{projects.d/archive,transcripts,templates,preferences}
   ```

## Key Concepts

### h.* Attributes
A shorthand for tracking human cognitive/emotional states. Claude uses these to calibrate its behavior -- reducing output density when you're visually overloaded, being terse when you're in deep focus, etc.

### Preference Modes
Say "mode: deep-work" and Claude shifts behavior instantly. Modes stack ("mode: music, deep-work"). Each mode is a simple markdown file describing how Claude should behave.

### Project Index (`/land`)
The `/land` skill graduates conversations into versioned project folders with SUMMARY.md files, history snapshots, and transcripts. A hot index (`~/.claude/projects.d/`) tracks what you're actively working on with a 30-day TTL.

### File Safety Rules
Three non-negotiable rules: backup dotfiles before editing, check symlinks before touching files, and never put secrets in config files. These prevent the most common "Claude broke my setup" scenarios.

## Customization

This is a starting point. The most valuable thing here is the framework, not the specific content. Adapt it to how you work.
