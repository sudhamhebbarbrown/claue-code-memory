# claude-memory-agents

A self-healing memory system for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Two custom agents automatically learn your preferences and keep memories clean -- so Claude gets better the more you use it.

## What it does

Claude Code has a built-in memory system (`~/.claude/projects/*/memory/`), but it's passive -- memories only get saved when Claude happens to notice something worth remembering. This project makes memory **active** and **self-maintaining**:

- **memory-extender** -- Runs in the background after substantive conversations. Extracts observations about you (preferences, expertise, style) and the project (decisions, deadlines, feedback) into the right places.
- **memory-compressor** -- Fires automatically when you end a session. Prunes stale, redundant, or code-derivable memories like an LRU cache. Keeps your global user profile under a 75-line cap.

Over time, Claude builds a profile of how you work and what you care about -- across all your projects.

## How it works

```
You have a conversation
        |
        v
memory-extender (background)
  - Writes user-level observations to ~/.claude/user-profile.md
  - Writes project-level observations to project memory
        |
        v
Session ends
        |
        v
memory-compressor (session-end hook)
  - Deletes stale/redundant memories
  - Merges overlapping entries
  - Enforces the 75-line user profile cap
  - Keeps MEMORY.md index under 200 lines
```

## Installation

### Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed
- `jq` (for JSON manipulation of settings)

### Quick install

```bash
git clone https://github.com/sudhamhebbarbrown/claue-code-memory.git
cd claue-code-memory
./install.sh
```

The installer:

1. Copies the two agent definitions to `~/.claude/agents/`
2. Adds a `SessionEnd` hook to `~/.claude/settings.json` that triggers the compressor
3. Appends instructions to `~/.claude/CLAUDE.md` telling Claude when to invoke the extender
4. Creates a global user profile template at `~/.claude/user-profile.md`

### Manual install

If you don't have `jq` or prefer to set things up yourself:

1. Copy `agents/*.md` to `~/.claude/agents/`
2. Add the session-end hook to `~/.claude/settings.json`:
   ```json
   {
     "hooks": {
       "SessionEnd": [
         {
           "matcher": "",
           "hooks": [
             {
               "type": "command",
               "command": "claude --agent memory-compressor -p 'Review and clean up the memory system. Prune stale, redundant, or code-derivable memories. Keep it tight.' 2>/dev/null &"
             }
           ]
         }
       ]
     }
   }
   ```
3. Append the contents of `snippets/claude-md-snippet.md` to `~/.claude/CLAUDE.md`
4. Copy `snippets/user-profile.md` to `~/.claude/user-profile.md`

## Uninstallation

```bash
./uninstall.sh
```

This removes the agents, hook, and CLAUDE.md snippet. Your accumulated memories and user profile are preserved -- delete them manually if you want a clean slate.

## What gets remembered (and what doesn't)

### Saved to `~/.claude/user-profile.md` (global)
- Your role and expertise
- Communication style preferences
- Workflow preferences (PR style, commit conventions)
- Quirks and pet peeves

### Saved to project memory
- Project-specific feedback and corrections
- Non-obvious decisions, deadlines, team agreements
- Pointers to external systems (Jira boards, dashboards, Slack channels)

### Never saved
- Code patterns or architecture (derivable from the codebase)
- Git history (use `git log`)
- Debugging steps (the fix is in the code)
- Ephemeral task state

## Project structure

```
.
├── agents/
│   ├── memory-compressor.md   # LRU-style cleanup agent (runs on session end)
│   └── memory-extender.md     # Observation extraction agent (runs in background)
├── snippets/
│   ├── claude-md-snippet.md   # Instructions appended to ~/.claude/CLAUDE.md
│   └── user-profile.md        # Template for ~/.claude/user-profile.md
├── install.sh
├── uninstall.sh
└── README.md
```

## License

MIT
