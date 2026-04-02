#!/usr/bin/env bash
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
AGENTS_DIR="$CLAUDE_DIR/agents"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"

echo "=== claude-memory-agents uninstaller ==="
echo ""

# --- 1. Remove agent files ---
echo "[1/3] Removing agents from $AGENTS_DIR"

for agent in memory-compressor.md memory-extender.md; do
  if [ -f "$AGENTS_DIR/$agent" ]; then
    rm "$AGENTS_DIR/$agent"
    echo "  -> Removed $agent"
  else
    echo "  -> $agent not found, skipping"
  fi
done

# --- 2. Remove hook from settings.json ---
echo "[2/3] Removing sessionEnd hook from $SETTINGS_FILE"

if ! command -v jq &>/dev/null; then
  echo "  -> jq not found. Manually remove the memory-compressor hook from $SETTINGS_FILE"
else
  if [ -f "$SETTINGS_FILE" ]; then
    if jq -e '.hooks.SessionEnd' "$SETTINGS_FILE" &>/dev/null; then
      UPDATED=$(jq '
        .hooks.SessionEnd = [
          .hooks.SessionEnd[] |
          select(.hooks | any(.command | contains("memory-compressor")) | not)
        ] |
        if .hooks.SessionEnd == [] then del(.hooks.SessionEnd) else . end |
        if .hooks == {} then del(.hooks) else . end
      ' "$SETTINGS_FILE")
      echo "$UPDATED" > "$SETTINGS_FILE"
      echo "  -> Hook removed"
    else
      echo "  -> No SessionEnd hooks found, skipping"
    fi
  else
    echo "  -> $SETTINGS_FILE not found, skipping"
  fi
fi

# --- 3. Remove CLAUDE.md snippet ---
echo "[3/3] Removing memory-extender instructions from $CLAUDE_MD"

if [ -f "$CLAUDE_MD" ] && grep -q "## Memory Agents" "$CLAUDE_MD"; then
  # Remove from "## Memory Agents" to "<!-- END Memory Agents -->" inclusive
  sed -i '' '/^## Memory Agents$/,/^<!-- END Memory Agents -->$/d' "$CLAUDE_MD"
  echo "  -> Instructions removed"
else
  echo "  -> Instructions not found, skipping"
fi

# --- 4. Ask about user profile ---
USER_PROFILE="$CLAUDE_DIR/user-profile.md"
if [ -f "$USER_PROFILE" ]; then
  echo ""
  echo "Note: ~/.claude/user-profile.md was NOT removed."
  echo "  It contains your accumulated preferences. Delete it manually if you want:"
  echo "  rm $USER_PROFILE"
fi

echo ""
echo "Done! Memory agents have been removed."
echo ""
echo "Note: Your existing memories in ~/.claude/projects/*/memory/ are untouched."
