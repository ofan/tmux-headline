#!/usr/bin/env bash
# SessionStart hook: register Claude session → tmux pane/window mapping
set -e

HEADLINE_DIR="$HOME/.claude/headline"
STATE_FILE="$HEADLINE_DIR/state.json"
mkdir -p "$HEADLINE_DIR/headlines"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id',''))" 2>/dev/null)

if [ -z "$SESSION_ID" ] || [ -z "$TMUX_PANE" ]; then
  exit 0
fi

PANE_ID="$TMUX_PANE"
WINDOW_INDEX=$(tmux display-message -p -t "$PANE_ID" '#I' 2>/dev/null || echo "")
TMUX_SESSION=$(tmux display-message -p -t "$PANE_ID" '#S' 2>/dev/null || echo "")

python3 << PYEOF
import json, os

state_file = "$STATE_FILE"
try:
    with open(state_file) as f:
        state = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    state = {}

state["$SESSION_ID"] = {
    "pane": "$PANE_ID",
    "window": "$WINDOW_INDEX",
    "tmux_session": "$TMUX_SESSION",
    "pid": $PPID,
    "cwd": os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
}

tmp = state_file + ".tmp"
with open(tmp, "w") as f:
    json.dump(state, f, indent=2)
os.rename(tmp, state_file)
PYEOF

exit 0
