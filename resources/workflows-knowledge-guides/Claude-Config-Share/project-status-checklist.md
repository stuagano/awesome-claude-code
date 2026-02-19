# Project Status Checklist -- Standard Format

This is the standard presentation format for project status on session start. When entering a project CWD that contains a SUMMARY.md, Claude reads it and presents status using this structure.

## Format Rules

1. **Always present on session entry** -- when CWD has a SUMMARY.md, show this checklist automatically
2. **Sections are adaptive** -- only show sections that have content. Don't show empty sections.
3. **Items are numbered** in actionable sections (so you can reference by number)
4. **Emoji markers** -- each section type has a header emoji. Items within a section use `- done-mark` (done) or `- open-mark N.` (open/actionable). Open Questions use `Q1.`, `Q2.`, etc.

## Section Order and Markers

Standard sections are listed below, but **new sections can be created on the fly** for any emerging category (blocked items, errors, rabbit holes, warnings, etc.). Use a fitting emoji for the header and follow the same item formatting rules.

```
### Done
- [done] Item that's done

### In Progress
- [ ] 1. Item actively being worked on (with context)

### Decided, Not Built
- [ ] 2. Decision made, implementation pending

### Blocked / Waiting
- [ ] 3. Item waiting on external dependency (note what's blocking)

### Separate Sessions
- [ ] 4. Item that needs its own dedicated session

### Open Questions
- Q1. Unresolved question or idea not yet actionable
```

### Ad-Hoc Section Examples

Create these as needed -- only include when there's actual content to show:

```
### Errors / Bugs
- [ ] 5. Description of error and current understanding

### Rabbit Holes
- [ ] 6. Tangent identified -- park it here, revisit if needed

### Warnings
- [ ] 7. Risk or concern worth tracking

### Research Needed
- [ ] 8. Topic requiring investigation before deciding
```

## Presentation Template

On session start, after reading SUMMARY.md:

```
Picked up <project-name> (v<N>, updated <date>). Here's where we are:

[Checklist sections with content]

Ready to pick up on any of these, or something new?
```

## Notes

- Numbering is continuous across all actionable sections (don't restart at 1 per section)
- Completed items don't need numbers (they're done)
- Open Questions use `Q1.`, `Q2.`, etc. (not checkboxes -- they're not tasks)
- Keep descriptions concise -- one line per item, details are in SUMMARY.md
- Ad-hoc sections slot in wherever they make sense in the flow
