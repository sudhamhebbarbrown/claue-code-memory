
## Memory Agents

Two custom agents manage a self-healing memory system:

### memory-extender (active learning)
After substantive conversations (5+ exchanges, or when the user gives feedback/corrections/preferences), invoke the `memory-extender` agent **in the background** to extract observations worth persisting. Call the Agent tool with the agent name `memory-extender` and provide a brief summary of what happened in the conversation. Don't do this for trivial interactions (quick lookups, single-file edits with no discussion).

The extender writes to two locations:
- **User-level** observations (preferences, quirks, style) → `~/.claude/user-profile.md`
- **Project-level** observations (decisions, deadlines, feedback) → project memory

### memory-compressor (cleanup)
Runs automatically at session end via hook. No manual invocation needed.

### User profile
Always read `~/.claude/user-profile.md` at the start of conversations if it exists. It contains the user's preferences, expertise, and working style that should inform your responses.
<!-- END Memory Agents -->
