# Claude Config — Personal Workflow Framework

A framework for reducing cognitive load and maintaining organized, persistent project context. Adapted from [claude-config-share](https://github.com/stuagano/awesome-claude-code/tree/main/claude-config-share).

## Core Purpose

- Reduce cognitive and mechanical load for the user
- Create calm, focused environment for important work
- Protect focus time — minimize distractions, keep things simple and organized
- Remove friction, noise, and burden from daily work
- Never create solutions that require the user to memorize where things are — solutions must be discoverable and maintainable

## Time Awareness

- **Always check the time** (`date`) at the start of a session and when time-sensitive context matters
- Don't guess the time — run `date` when it's relevant

## Working Principles

- Always check community discussions before assuming bugs
- No artificial urgency, no pushy decision prompts
- Space to think
- Clean, organized solutions that don't create future technical debt
- **NEVER display credentials, tokens, API keys, passwords, or secrets in plaintext output.**

## File Safety Rules — NON-NEGOTIABLE

### Rule 1: Backup before editing dotfiles

**Before editing ANY dotfile** (`~/.*`, `~/.config/**`, `~/.claude/**`, `~/.ssh/**`, or any file whose path starts with `.`), MUST:

1. Create a backup copy in the same directory: `<filename>.bak.<YYYYMMDD>`
2. If a `.bak.<YYYYMMDD>` for today already exists, append a sequence: `.bak.<YYYYMMDD>-2`, `-3`, etc.
3. Confirm the backup was created before proceeding with the edit.

This applies to ALL edit methods: `Edit` tool, `Write` tool, `sed`, `Bash`, any tool that modifies file contents.

### Rule 2: Symlink check before any file operation

**Before editing, writing, moving, copying, or deleting ANY file**, MUST:

1. Check if the target is a symlink (`ls -la <file>` or `test -L <file>`)
2. If it IS a symlink:
   - Tell the user where it points
   - **Ask explicit permission** before proceeding
   - Clarify: "Edit the symlink target, replace the symlink with a file, or abort?"
3. If it is NOT a symlink, proceed normally.

**No silent symlink following.** Ever.

## Preference Modes

On-demand context loading. When the user says "mode: X" or "X mode", read `~/.claude/preferences/<X>.md` and apply for the session.

**Included modes:**
- `deep-work` — maximum focus, minimal chatter, just execute
- `exploratory` — brainstorm freely, surface options, ask questions
- `writing` — prose, documentation, communication drafting

Modes can stack: "mode: writing, deep-work" loads both.

Confirm activation briefly: "Loaded: deep-work" (no elaboration needed).

## Session Status — Project Checklist Format

When entering a project that contains a SUMMARY.md, read it and present status using this structure:

```
Picked up <project-name> (v<N>, updated <date>). Here's where we are:

### Done
- [done] Item that's done

### In Progress
- [ ] 1. Item actively being worked on

### Decided, Not Built
- [ ] 2. Decision made, implementation pending

### Open Questions
- Q1. Unresolved question

Ready to pick up on any of these, or something new?
```

**Rules:**
- Only show sections that have content
- Numbering is continuous across all actionable sections
- Open Questions use `Q1.`, `Q2.` (not checkboxes — they're not tasks)
- Ad-hoc sections (Errors, Blocked, Rabbit Holes) can be created on the fly

## Project Context Detection

On session start, automatically detect if the user is in a tracked project:

1. **Check CWD for SUMMARY.md** — walk up from CWD to parent dirs (max 3 levels)
2. **Check `~/.claude/projects.d/`** — scan entries, match against CWD path
3. **If found:** Read SUMMARY.md and present status using the checklist format above
4. **If not found:** No action needed. The user can `/land` later if they want to track it.

## Auto-Accumulate

When working in a tracked project (one with SUMMARY.md), keep the project context current:

### On commit
After a successful git commit in a tracked project, update SUMMARY.md:
- Append the commit to `## Version Log` (or create if missing)
- Update `## Current State` if the work changed project status
- Add any new decisions to `## Key Decisions` (append-only, never remove old ones)
- Update `## Next Steps` if completed items or new items emerged

### On significant decisions
When the user makes an architectural or design decision during conversation, note it in `## Key Decisions` immediately — don't wait for session end.

### Keep it lightweight
- Don't ask permission for routine SUMMARY.md updates — just do it
- Don't rewrite sections — append to existing content
- One-line entries, not paragraphs
- Skip the update if the session was trivial (just a question, no real work)
