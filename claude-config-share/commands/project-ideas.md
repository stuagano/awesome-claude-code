---
description: Brainstorm, capture, and manage project ideas from conversation context
argument-hint: [action] (e.g., list, add "idea name", develop 3, prune)
allowed-tools: Bash(date:*),Bash(ls:*),Bash(mkdir:*),Read,Write,Edit,Glob,Grep
---

## Project Ideas -- Capture and Develop Ideas from Conversations

Also triggered by natural language: "I have an idea for...", "what if we built...", "add this to my ideas", "show me my ideas", "brainstorm projects".

### Overview

Project Ideas is a lightweight idea backlog that lives alongside `/land` projects. Ideas start as rough notes and can be developed into full `/land` projects when they're ready.

**Ideas file:** `~/projects/.ideas/IDEAS.md`
**Individual idea files:** `~/projects/.ideas/<slug>.md`

### Step 0: Get the current time

Run `date` to get the current timestamp. Use for all date fields.

### Step 1: Determine the action

Parse the argument to determine what the user wants:

| Argument | Action |
|----------|--------|
| _(none)_ | Show all ideas grouped by status |
| `add "name"` or just a description | Capture a new idea |
| `develop <number>` | Flesh out an idea with notes, scope, and next steps |
| `land <number>` | Graduate an idea to a full `/land` project |
| `prune` | Review and archive stale ideas |
| `list` | Same as no argument -- show all ideas |

### Step 2: Ensure the ideas directory exists

```bash
mkdir -p ~/projects/.ideas
```

If `~/projects/.ideas/IDEAS.md` doesn't exist, create it with the initial template (see format below).

### Step 3: Execute the action

#### Action: Add

1. Generate a slug from the idea name (lowercase, hyphens, no special chars)
2. Check for duplicates -- tokenize and compare against existing ideas (same fuzzy logic as `/land` Step 2)
3. If no duplicate, append to `IDEAS.md` under `## Active Ideas`
4. Create individual idea file `~/projects/.ideas/<slug>.md` with the detail template
5. Confirm: "Added idea #N: <name>"

#### Action: List / Show

1. Read `~/projects/.ideas/IDEAS.md`
2. Present ideas grouped by status with numbers for easy reference:
   ```
   Active Ideas:
     1. Widget Dashboard -- quick app to track widget metrics (added 2026-02-10)
     2. CLI Tool for Logs -- parse and summarize log files (added 2026-02-15)

   Developing:
     3. Auth Service Rewrite -- centralize auth across microservices (added 2026-01-20)

   Archived: 2 ideas (use "project-ideas archived" to see)
   ```

#### Action: Develop

1. Read the idea's individual file `~/projects/.ideas/<slug>.md`
2. Based on conversation context and the idea's current notes, expand:
   - **Problem statement** -- what does this solve?
   - **Rough scope** -- what would a v1 look like?
   - **Key questions** -- what needs to be figured out?
   - **Potential stack** -- technologies, tools, patterns
   - **Next steps** -- 3-5 concrete actions to move forward
3. Update the idea's status to "developing" in `IDEAS.md`
4. Save expanded notes to the individual idea file
5. Confirm: "Developed idea #N: <name>. Use `/project-ideas land N` when ready to start."

#### Action: Land

1. Read the idea's individual file
2. Invoke the `/land` command with the idea name as the project name
3. Copy relevant context from the idea file into the new project's SUMMARY.md
4. Move the idea to "Landed" status in `IDEAS.md` with a link to the project path
5. Confirm: "Landed idea #N as project at <path>/. Use `cd <path> && claude` to start."

#### Action: Prune

1. Read all ideas from `IDEAS.md`
2. For each idea older than 30 days with status "active" (not "developing"):
   - Present it to the user: "Idea #N: <name> (added <date>) -- keep, develop, or archive?"
3. Move archived ideas to `## Archived` section
4. Summarize: "Pruned N ideas (archived M, kept K)"

### IDEAS.md Format

```markdown
# Project Ideas

**Last updated:** YYYY-MM-DD
**Total:** N active, N developing, N archived

## Active Ideas

| # | Name | Added | Tags | One-liner |
|---|------|-------|------|-----------|
| 1 | Widget Dashboard | 2026-02-10 | frontend, metrics | Quick app to track widget metrics |

## Developing

| # | Name | Added | Tags | One-liner |
|---|------|-------|------|-----------|
| 3 | Auth Service Rewrite | 2026-01-20 | backend, security | Centralize auth across microservices |

## Landed

| # | Name | Landed | Project Path |
|---|------|--------|--------------|
| 5 | Log Parser | 2026-02-01 | ~/projects/log-parser/ |

## Archived

| # | Name | Added | Archived | Reason |
|---|------|-------|----------|--------|
| 4 | Old Idea | 2026-01-05 | 2026-02-15 | Superseded by other work |
```

### Individual Idea File Format

File: `~/projects/.ideas/<slug>.md`

```markdown
# <Idea Name>

**Status:** active | developing | landed | archived
**Added:** YYYY-MM-DD
**Tags:** tag1, tag2
**Source:** <brief note on where the idea came from>

## One-liner

<Single sentence describing the idea.>

## Notes

<Free-form notes, conversation excerpts, links, anything relevant.>

## Problem Statement

<Filled in during "develop" -- what does this solve?>

## Rough Scope (v1)

<Filled in during "develop" -- minimal viable version.>

## Key Questions

<Filled in during "develop" -- what needs answers before building.>

## Potential Stack

<Filled in during "develop" -- technologies, patterns, tools.>

## Next Steps

<Filled in during "develop" -- concrete actions to move forward.>
```

### Important Rules

- Ideas are cheap -- capture liberally, prune regularly
- The fuzzy dedup check applies here too -- don't create duplicate ideas
- When developing an idea, draw from the current conversation context
- Landing an idea delegates to `/land` -- don't duplicate that logic
- Tags are freeform but keep them consistent (check existing tags first)
- Numbers are stable within a session but may shift after prune/archive operations
