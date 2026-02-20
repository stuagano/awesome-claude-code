---
description: Land a conversation into a project folder with summary and versioning
argument-hint: [project-name] (e.g., my-project, Terminal Setup)
allowed-tools: Bash(mkdir:*),Bash(date:*),Bash(ls:*),Bash(cp:*),Bash(mv:*),Bash(git:*),Read,Write,Edit,Glob,Grep
---

## Land -- Graduate a Conversation to a Project

Also triggered by natural language: "put this chat in X", "store this chat in X", "land this in X", "move this to X", "file this under X".

### Step 0: Get the current time

Run `date` to get the current timestamp. Use for all date fields.

### Step 1: Determine the target path

**If argument provided:** Use it as the project name/path.
**If no argument:** Suggest 2-3 project names based on conversation topics. Ask the user to pick or name one.

**Default landing directory:** `~/projects/` (customize to your preferred project root).

Examples:
- `terminal-colors` -> `~/projects/terminal-colors/`
- `My Cool Project` -> `~/projects/My Cool Project/`
- `~/code/widget-app` -> `~/code/widget-app/` (explicit override)

**Exception:** If the target directory doesn't exist, ask the user to confirm before creating it.

### Step 2: Fuzzy dedup check (CRITICAL -- NON-OPTIONAL)

Before creating anything, check for similar existing projects.

1. **Scan existing projects:**
   - `ls -d ~/projects/*/ 2>/dev/null`
   - Read all entries in `~/.claude/projects.d/` (parse `path:` field from each)

2. **Tokenize the proposed path:**
   - Split on `/`, `-`, `_`, spaces
   - Example: `important-things` -> tokens: `important`, `things`

3. **Compare against every existing project name:**
   - Tokenize each existing project the same way
   - Flag if ANY of these are true:
     - **Word overlap:** >50% of tokens match (in any order)
     - **Substring match:** Proposed name contains or is contained in an existing name
     - **Typo detection:** Any token has edit distance <= 2 from an existing token AND other tokens overlap
     - **Semantic near-miss:** Obvious synonyms match
   - Common synonym pairs: important/critical/key, things/stuff/items, notes/thoughts/ideas, info/information/data, work/projects/tasks, config/settings/prefs/preferences

4. **If similar projects found:**
   ```
   Found similar projects:
     1. ~/projects/important-stuff/ (last touched 2026-01-15)

   Are these different from "important-things", or should we merge into one?
   ```
   Wait for the user's answer before proceeding.

5. **If no similar projects:** Proceed to Step 3.

### Step 3: Create or update the project

**If NEW project:**

1. Create directory: `<resolved-path>/`
2. Create `<resolved-path>/transcripts/`
3. Create `<resolved-path>/history/`
4. Write `<resolved-path>/SUMMARY.md` (see format below)
5. Ensure CLAUDE.md (see "CLAUDE.md Auto-Creation" below)
6. Copy SUMMARY.md to `<resolved-path>/history/SUMMARY-v1.md`
7. Write conversation transcript to `<resolved-path>/transcripts/YYYY-MM-DD-HHMM.md`
8. Create hot index reference at `~/.claude/projects.d/<path-with-dashes>.md`
9. Confirm: "Landed at <resolved-path>/ (v1). Fresh session: `cd <resolved-path> && claude`"

**If EXISTING project (update):**

1. Read existing `<resolved-path>/SUMMARY.md`
2. Copy current SUMMARY.md to `<resolved-path>/history/SUMMARY-v<current>.md` (snapshot before changes)
3. Increment version number
4. Update `Last updated` date
5. Append new entry to `## Version Log`
6. Update `## Summary`, `## Current State`, `## Next Steps` with current conversation context
7. Accumulate `## Key Decisions` (never remove old ones)
8. Preserve all previous `## Source Conversations` references, add new one
9. Ensure CLAUDE.md (see "CLAUDE.md Auto-Creation" below)
10. Save new transcript to `<resolved-path>/transcripts/YYYY-MM-DD-HHMM.md`
11. Touch the hot index reference (reset TTL to 30 days)
12. Confirm: "Updated <resolved-path>/ (v<N>). Fresh session: `cd <resolved-path> && claude`"

### SUMMARY.md Format

```markdown
# <Project Title>

**Path:** <resolved-path>/
**Created:** YYYY-MM-DD
**Last updated:** YYYY-MM-DD
**Version:** <N>
**Keywords:** keyword1, keyword2, keyword3

## Summary

<2-4 sentence overview of what this project/topic is about.>

## Current State

<What's true right now. Active decisions, open questions, current status.>

## Key Decisions

<Bullet list of decisions made during conversations. Accumulates across versions.>

## Next Steps

<Numbered list of actionable items, ordered by priority.>

## Version Log

| Version | Date | Summary |
|---------|------|---------|
| 1 | YYYY-MM-DD | Initial landing from conversation about X |

## Source Conversations

- `transcripts/YYYY-MM-DD-HHMM.md` -- <brief description>
```

### Hot Index Reference Format

File: `~/.claude/projects.d/<path-with-dashes>.md`

```markdown
---
path: <resolved-path>
created: YYYY-MM-DD
last_touched: YYYY-MM-DD
ttl_days: 30
expires: YYYY-MM-DD
---
# <Project Title>
<One-line summary for search matching>
Keywords: keyword1, keyword2, keyword3
```

### CLAUDE.md Auto-Creation

Every landed project should be self-orienting. This step ensures a CLAUDE.md exists with an instruction to read SUMMARY.md.

**Required line:** `Read SUMMARY.md to get context on this project before starting work.`

**Logic:**
1. If `<resolved-path>/CLAUDE.md` does not exist -> create it with the required line
2. If `<resolved-path>/CLAUDE.md` exists but does not contain the required line -> append the required line
3. If `<resolved-path>/CLAUDE.md` exists and already contains the required line -> no change

### Important Rules

- SUMMARY.md is a landing page, not a transcript. Keep it concise.
- Version Log is append-only -- never delete previous entries.
- Key Decisions accumulate across all versions -- never remove old ones.
- Always snapshot SUMMARY.md to history/ before updating.
- Always preserve previous Source Conversations references.
- The fuzzy dedup check is NON-OPTIONAL. Always run it.
