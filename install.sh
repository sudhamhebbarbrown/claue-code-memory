#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
AGENTS_DIR="$CLAUDE_DIR/agents"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"

HOOK_COMMAND="claude --agent memory-compressor -p 'Review and clean up the memory system. Prune stale, redundant, or code-derivable memories. Keep it tight.' 2>/dev/null &"

echo "=== claude-memory-agents installer ==="
echo ""

# --- 1. Check for jq ---
if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required but not installed."
  echo ""
  echo "Install it:"
  echo "  macOS:  brew install jq"
  echo "  Ubuntu: sudo apt install jq"
  echo "  Arch:   sudo pacman -S jq"
  echo ""
  echo "Or install manually — see README.md for steps."
  exit 1
fi

# --- 2. Copy agents ---
echo "[1/4] Installing agents to $AGENTS_DIR"
mkdir -p "$AGENTS_DIR"
cp "$SCRIPT_DIR/agents/memory-compressor.md" "$AGENTS_DIR/memory-compressor.md"
cp "$SCRIPT_DIR/agents/memory-extender.md" "$AGENTS_DIR/memory-extender.md"
echo "  -> memory-compressor.md"
echo "  -> memory-extender.md"

# --- 3. Merge sessionEnd hook into settings.json ---
echo "[2/4] Adding sessionEnd hook to $SETTINGS_FILE"

if [ ! -f "$SETTINGS_FILE" ]; then
  echo '{}' > "$SETTINGS_FILE"
  echo "  -> Created $SETTINGS_FILE"
fi

# Check if hook already exists
if jq -e '.hooks.SessionEnd[]?.hooks[]?.command // empty' "$SETTINGS_FILE" 2>/dev/null | grep -q "memory-compressor"; then
  echo "  -> Hook already present, skipping"
else
  HOOK_ENTRY=$(cat <<'HOOKJSON'
{
  "matcher": "",
  "hooks": [
    {
      "type": "command",
      "command": "claude --agent memory-compressor -p 'Review and clean up the memory system. Prune stale, redundant, or code-derivable memories. Keep it tight.' 2>/dev/null &"
    }
  ]
}
HOOKJSON
)

  # Merge: create hooks.SessionEnd array if missing, append our entry
  UPDATED=$(jq --argjson hook "$HOOK_ENTRY" '
    .hooks //= {} |
    .hooks.SessionEnd //= [] |
    .hooks.SessionEnd += [$hook]
  ' "$SETTINGS_FILE")

  echo "$UPDATED" > "$SETTINGS_FILE"
  echo "  -> Hook added"
fi

# --- 4. Append CLAUDE.md snippet ---
echo "[3/4] Adding memory-extender instructions to $CLAUDE_MD"


if [ -f "$CLAUDE_MD" ] && grep -q "## Memory Agents" "$CLAUDE_MD"; then
  echo "  -> Instructions already present, skipping"
else
  cat "$SCRIPT_DIR/snippets/claude-md-snippet.md" >> "$CLAUDE_MD"
  echo "  -> Instructions appended"
fi

# --- 5. Create user profile if it doesn't exist ---
USER_PROFILE="$CLAUDE_DIR/user-profile.md"
echo "[4/4] Setting up global user profile at $USER_PROFILE"

if [ -f "$USER_PROFILE" ]; then
  echo "  -> User profile already exists, skipping"
else
  cp "$SCRIPT_DIR/snippets/user-profile.md" "$USER_PROFILE"
  echo "  -> Created user profile template"
fi

echo ""
echo "Done! Memory agents are now active."
echo ""
echo "  memory-extender: Claude will invoke it during substantive conversations"
echo "  memory-compressor: Fires automatically when you exit a session"
echo "  user-profile:     Global profile at $USER_PROFILE (fills in over time)"
echo ""
echo "To uninstall: ./uninstall.sh"
