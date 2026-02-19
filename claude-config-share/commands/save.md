---
description: Quick-save session context to an existing project's SUMMARY.md
argument-hint: [project-name] (e.g., my-project)
allowed-tools: Bash(date:*),Bash(ls:*),Bash(cp:*),Read,Write,Edit,Glob,Grep
---

## Save -- Quick Checkpoint for an Existing Project

Lightweight alternative to `/land`. Updates an existing project's SUMMARY.md without creating new folders or transcripts. Use this for quick context saves mid-session.

Also triggered by natural language: "save this to X", "checkpoint X", "update X with this".

### Step 0: Get the current time

Run `date` to get the current timestamp.

### Step 1: Resolve the project

**If argument provided:** Look up the project by name:
1. Check `~/projects/<argument>/SUMMARY.md`
2. Check `~/.claude/projects.d/` for a matching hot index entry

**If no argument and CWD has a SUMMARY.md:** Use the current project.

**If no argument and no SUMMARY.md in CWD:** List recent projects from `~/.claude/projects.d/` and ask the user to pick one.

**If project not found:** Suggest using `/land` instead to create it.

### Step 2: Read current state

1. Read `<project-path>/SUMMARY.md`
2. Note the current version number

### Step 3: Save

1. Copy current SUMMARY.md to `<project-path>/history/SUMMARY-v<current>.md` (snapshot)
2. Increment version number
3. Update `Last updated` date
4. Update these sections from current conversation context:
   - `## Current State` -- overwrite with current status
   - `## Key Decisions` -- append new decisions (never remove old ones)
   - `## Next Steps` -- overwrite with current priorities
5. Append to `## Version Log`:
   ```
   | <N+1> | YYYY-MM-DD | Quick save: <brief description of what changed> |
   ```
6. Touch the hot index reference in `~/.claude/projects.d/` (reset TTL)
7. Confirm: "Saved <project-name> (v<N+1>)."

### Important Rules

- Save is fast and automatic -- no prompts, no confirmations beyond the final status
- Never create new directories or transcript files (that's what `/land` is for)
- Key Decisions are append-only -- never remove previous entries
- Always snapshot to history/ before updating
- If the project doesn't exist, don't create it -- redirect to `/land`
