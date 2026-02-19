# Claude Config Share — Personal Workflow Kit

A framework for configuring Claude Code to reduce cognitive load and maintain organized, persistent project context. Includes switchable behavioral modes, a conversation-to-project archival system (`/land`), and safety rules for dotfile editing.

## What's Included

| Resource | Type | Purpose |
|----------|------|---------|
| `CLAUDE.md` template | CLAUDE.md file | Core config: safety rules, time awareness, modes, session status |
| `/land` | Slash command | Graduate conversations into versioned project folders |
| Preference modes | Workflow files | Switchable behavioral modes (deep-work, exploratory, writing) |
| Project status checklist | Template | Standard format for resuming work across sessions |

## Preference Modes

Modes are activated by saying "mode: X" and change Claude's behavior instantly. They stack ("mode: writing, deep-work").

### Deep Work Mode

Maximize focus. Minimize everything else.

- Execute, don't discuss
- No preamble, no confirmation chatter
- No offering alternatives unless asked
- Terse responses
- Bias toward action over clarification

### Exploratory Mode

Understanding over focus.

- Think out loud
- Surface options and tradeoffs
- Ask clarifying questions freely
- Brainstorm without filtering
- Tangents are okay if they're valuable

### Writing Mode

For prose, documentation, communication.

- Professional but warm tone
- Clear over clever, no corporate buzzwords
- Short paragraphs, active voice
- Match the user's voice, not generic AI voice
- Flag unclear antecedents, catch repetition

## The `/land` System

Graduates ephemeral conversations into versioned, self-orienting project folders:

```
~/projects/<name>/
├── SUMMARY.md          # Living document (versioned, accumulates decisions)
├── CLAUDE.md           # Auto-created, points to SUMMARY.md
├── transcripts/        # Raw conversation exports (timestamped)
└── history/            # SUMMARY.md snapshots (SUMMARY-v1.md, v2, etc.)
```

Key features:
- **Fuzzy dedup** — tokenizes names and checks word overlap, substrings, edit distance, and synonyms before creating
- **Append-only accumulation** — Key Decisions and Version Log never delete old entries
- **Hot index** — `~/.claude/projects.d/` tracks active projects with 30-day TTL
- **Self-orienting** — auto-created CLAUDE.md ensures new sessions read SUMMARY.md

## Installation

These resources are installed automatically via `deck setup` when selecting the "Personal workflow" need, or individually via `/pick`:

```bash
# Via deck setup
deck setup ~/my-project    # select "Personal workflow" when prompted

# Via /pick
/pick slash-commands/land
/pick claude.md-files/Claude-Config-Share
```

To install the preference mode files manually:

```bash
mkdir -p ~/.claude/preferences
# Copy deep-work.md, exploratory.md, writing.md into ~/.claude/preferences/
```

## Source

Adapted from [claude-config-share](https://github.com/stuagano/awesome-claude-code/tree/main/claude-config-share).
