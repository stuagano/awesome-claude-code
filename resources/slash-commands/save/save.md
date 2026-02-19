---
description: Quick-save current session context to the project's SUMMARY.md
argument-hint: [optional note about what was done]
allowed-tools: Bash(date:*),Bash(ls:*),Bash(cp:*),Read,Write,Edit,Glob,Grep
---

## Save -- Quick Project Context Update

Lightweight alternative to `/land`. Updates an existing project's SUMMARY.md with what happened this session. No new folders, no transcripts, no ceremony.

Also triggered by: "save progress", "update the project", "checkpoint".

### Step 0: Find the project

1. Look for SUMMARY.md in CWD, then parent dirs (max 3 levels up)
2. If not found, check `~/.claude/projects.d/` for a match against CWD
3. **If no project found:** Tell the user and suggest `/land` to create one. Stop here.

### Step 1: Read current state

1. Run `date` for timestamp
2. Read the existing SUMMARY.md

### Step 2: Update SUMMARY.md

Apply these updates (only sections that changed):

**`## Current State`** — Replace with what's true now. Keep it to 2-4 lines.

**`## Key Decisions`** — Append any new decisions from this session. Never remove old ones.

**`## Next Steps`** — Update: remove completed items, add new ones, re-order by priority.

**`## Version Log`** — Append one row:

```
| <N+1> | YYYY-MM-DD | <one-line summary of this session's work> |
```

**`Last updated`** — Update the date in the header metadata.

**`Version`** — Increment by 1.

### Step 3: Snapshot

1. Copy current SUMMARY.md to `history/SUMMARY-v<N>.md` (the version before this update)
2. Write the updated SUMMARY.md

### Step 4: Confirm

```
Saved <project-name> (v<N+1>). <one-line summary>
```

### Rules

- **Fast and quiet.** No prompts, no confirmations, no previews. Just save.
- If the user provided a note argument, use it as the version log summary.
- If no argument, summarize from conversation context.
- Don't touch `## Summary` unless the project's purpose fundamentally changed.
- Don't create transcripts (that's `/land`'s job).
- Don't run fuzzy dedup (project already exists).
- Touch the hot index file if it exists (`~/.claude/projects.d/`): update `last_touched` and `expires`.
