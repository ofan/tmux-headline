#!/usr/bin/env bash
# Stop hook: sync headlines to tmux options AND rename Claude session

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id',''))" 2>/dev/null)
TRANSCRIPT=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('transcript_path',''))" 2>/dev/null)

# Sync tmux options
"${CLAUDE_PLUGIN_ROOT}/scripts/headline-sync.sh"

# Write headline as Claude session name (custom-title)
if [ -n "$SESSION_ID" ] && [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  HEADLINE_FILE="$HOME/.claude/headline/headlines/${SESSION_ID}.headline"
  if [ -f "$HEADLINE_FILE" ]; then
    HEADLINE=$(head -c 40 "$HEADLINE_FILE" | tr -d '\n')
    if [ -n "$HEADLINE" ]; then
      printf '{"type":"custom-title","customTitle":"%s"}\n' "$HEADLINE" >> "$TRANSCRIPT"
    fi
  fi
fi

exit 0
