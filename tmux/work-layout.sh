#!/usr/bin/env bash
# Generic fallback layout — used when no machine-local layout.sh exists.
# Creates a session with the main-vertical layout: left pane + right column.
# Name priority: $1 arg > TMUX_WORK_SESSION env var > "work"

set -euo pipefail

SESSION="${1:-${TMUX_WORK_SESSION:-work}}"
WIN="main"

command -v tmux >/dev/null 2>&1 || { echo "tmux not found" >&2; exit 1; }

attach_or_switch() {
  if [[ -n "${TMUX:-}" ]]; then
    tmux switch-client -t "$SESSION"
  else
    tmux attach -t "$SESSION"
  fi
}

if tmux has-session -t "$SESSION" 2>/dev/null; then
  attach_or_switch
  exit 0
fi

tmux new-session -ds "$SESSION" -n "$WIN" -c "${HOME}"
tmux send-keys -t "$SESSION:$WIN" 'claude -r' C-m
tmux split-window -h -t "$SESSION:$WIN" -c "#{pane_current_path}"
tmux split-window -v -t "$SESSION:$WIN" -c "#{pane_current_path}"
tmux split-window -v -t "$SESSION:$WIN" -c "#{pane_current_path}"
tmux select-layout -t "$SESSION:$WIN" main-vertical

attach_or_switch
