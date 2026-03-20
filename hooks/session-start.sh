#!/usr/bin/env bash
# SessionStart hook: register Claude session → tmux pane/window mapping
# Handles re-registration: cleans up stale entries for the same pane
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
import json, os, subprocess

state_file = "$STATE_FILE"
pane_id = "$PANE_ID"
session_id = "$SESSION_ID"

try:
    with open(state_file) as f:
        state = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    state = {}

# Remove stale entries pointing to the same pane (old session replaced in same pane)
stale = [sid for sid, info in state.items() if info.get("pane") == pane_id and sid != session_id]
for sid in stale:
    state.pop(sid)

# If this session existed on a different pane, clear old pane's tmux options
if session_id in state and state[session_id].get("pane") != pane_id:
    old_pane = state[session_id].get("pane", "")
    if old_pane:
        subprocess.run(["tmux", "set-option", "-p", "-t", old_pane, "-u", "@pane_headline"],
                       capture_output=True)

state[session_id] = {
    "pane": pane_id,
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
