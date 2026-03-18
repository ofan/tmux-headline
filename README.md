# tmux-headline

Claude Code plugin that shows session headlines and an animated spinner in your tmux status bar.

Instead of every window showing `claude`, you see what each session is actually working on:

```
 0 ✳ openclaw dashboard   1 ✶ memclaw dev   2 · disclaw session
```

- Busy sessions show an animated spinner (cycles every second)
- Idle sessions show `✳`
- Non-Claude windows are unaffected

## Install

```sh
# Via marketplace (if registered)
/plugin marketplace add ofan/tmux-headline

# Or load directly
claude --plugin-dir /path/to/tmux-headline
```

Then add `pluginDirs` to `~/.claude/settings.json` for persistent loading:

```json
{
  "pluginDirs": ["/path/to/tmux-headline"]
}
```

## tmux config

Add these to your `~/.tmux.conf`:

```tmux
# Dark status bar
set -g status-style "bg=colour237,fg=colour248"
set -g status-interval 1

# Window tabs — Claude windows show spinner + headline, others show name
set -g window-status-format " #I #{?#{@headline},#{?#{m:✳*,#{pane_title}},#[fg=colour244]✳,#[fg=yellow]#(/path/to/tmux-headline/scripts/spinner.sh)#[default]}#[fg=colour244] #{=18:@headline}#[default],#W} "
set -g window-status-current-format "#[fg=colour15,bg=colour239,bold] #I #{?#{@headline},#{?#{m:✳*,#{pane_title}},✳,#[fg=yellow]#(/path/to/tmux-headline/scripts/spinner.sh)#[fg=colour15]} #{=18:@headline},#W} #[default]"
set -g window-status-separator " "

# Pane border with headline
set -g pane-border-status top
set -g pane-border-format "#{pane_index} #{?#{@pane_headline},#[fg=colour90]#{@pane_headline}#[default] ,}#[fg=cyan]#{session_name}#[default] #{pane_title} #[dim]#{b:pane_current_path}#[default]"
```

Replace `/path/to/tmux-headline` with the actual plugin path (e.g. `~/.claude/plugins/local/tmux-headline`).

## How it works

Four hooks working together:

| Hook | What it does |
|------|-------------|
| **SessionStart** | Registers session ID → tmux pane/window mapping in `state.json` |
| **UserPromptSubmit** | Injects a system reminder asking Claude to write a short headline |
| **Stop** | Syncs headline files to tmux `@headline`/`@pane_headline` options; re-appends `custom-title` to session `.jsonl` so `/resume` shows the headline |
| **SessionEnd** | Cleans up state and headline files |

Runtime state lives in `~/.claude/headline/`:
- `state.json` — session → tmux pane mapping
- `headlines/<session-id>.headline` — plain text headline per session

## Spinner styles

Set `HEADLINE_SPINNER` env var to switch:

| Style | Frames | Description |
|-------|--------|-------------|
| `flowers` (default) | `· ✢ ✽ ✶ ✽ ✢` | Star glyphs, small → big → small |
| `claude` | `⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏` | Claude's actual braille spinner |
| `braille` | 16 frames | Clockwise fill and drain |
| `dots` | `· • ● • ·` | Pulsing dot |

```sh
export HEADLINE_SPINNER=claude
```

## Session naming

The plugin automatically names your Claude sessions with the headline text. When you `/resume`, you'll see descriptive names like "tmux headline plugin" instead of random slugs like "swirling-chasing-dewdrop".

This works by appending `{"type":"custom-title"}` entries to the session `.jsonl` file on every Stop hook — keeping the title within Claude's 64KB tail scan window.

## Requirements

- tmux 3.1+ (for `#{m:pattern}` format matching)
- Claude Code 2.1.50+
- Python 3 (for JSON state management in hooks)

## License

MIT
