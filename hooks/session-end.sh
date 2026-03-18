#!/usr/bin/env bash
# SessionEnd hook: clean up state and headline files

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id',''))" 2>/dev/null)

if [ -z "$SESSION_ID" ]; then
  exit 0
fi

HEADLINE_DIR="$HOME/.claude/headline"
STATE_FILE="$HEADLINE_DIR/state.json"

# Remove from state.json
python3 << PYEOF
import json, os
state_file = "$STATE_FILE"
try:
    with open(state_file) as f:
        state = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    exit()
state.pop("$SESSION_ID", None)
tmp = state_file + ".tmp"
with open(tmp, "w") as f:
    json.dump(state, f, indent=2)
os.rename(tmp, state_file)
PYEOF

rm -f "$HEADLINE_DIR/headlines/${SESSION_ID}.headline"

# Clear tmux pane option
if [ -n "$TMUX_PANE" ]; then
  tmux set-option -p -t "$TMUX_PANE" -u @pane_headline 2>/dev/null || true
fi

exit 0
