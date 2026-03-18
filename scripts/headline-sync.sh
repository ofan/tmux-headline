#!/usr/bin/env bash
# Reads state.json + headline files, sets tmux @headline and @pane_headline options

HEADLINE_DIR="$HOME/.claude/headline"
STATE_FILE="$HEADLINE_DIR/state.json"

[ -f "$STATE_FILE" ] || exit 0

python3 << 'PYEOF'
import json, os, subprocess

state_file = os.path.expanduser("~/.claude/headline/state.json")
headlines_dir = os.path.expanduser("~/.claude/headline/headlines")

try:
    with open(state_file) as f:
        state = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    exit()

for sid, info in state.items():
    pane = info.get("pane", "")
    if not pane:
        continue

    headline = ""
    headline_file = os.path.join(headlines_dir, f"{sid}.headline")
    try:
        with open(headline_file) as f:
            headline = f.read().strip()[:20]
    except FileNotFoundError:
        pass

    if headline:
        subprocess.run(
            ["tmux", "set-option", "-p", "-t", pane, "@pane_headline", headline],
            capture_output=True
        )
        window = info.get("window", "")
        tmux_session = info.get("tmux_session", "")
        if window and tmux_session:
            subprocess.run(
                ["tmux", "set-option", "-w", "-t", f"{tmux_session}:{window}", "@headline", headline],
                capture_output=True
            )
PYEOF

exit 0
