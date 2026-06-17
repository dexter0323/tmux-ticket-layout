#!/usr/bin/env bash
# Example: simple 2-pane layout (left: AI, right: scratch)
# Copy to ~/.config/tmux/layout.sh and adapt paths to use.

set -euo pipefail

PROJECT_ROOT="${HOME}/dev/my-project"
WORKTREE_BASE="${PROJECT_ROOT}/.worktrees"

TICKET="${1:-}"
[[ -z "$TICKET" ]] && { echo "Usage: layout.sh <ticket-id>" >&2; exit 1; }

SESSION="$TICKET"
WIN="$TICKET"
WORKTREE="${WORKTREE_BASE}/${TICKET}"

attach_or_switch() {
  if [[ -n "${TMUX:-}" ]]; then tmux switch-client -t "$SESSION"
  else tmux attach -t "$SESSION"; fi
}

tmux has-session -t "$SESSION" 2>/dev/null && { attach_or_switch; exit 0; }

if [[ ! -d "$WORKTREE" ]]; then
  mkdir -p "$WORKTREE_BASE"
  git -C "$PROJECT_ROOT" worktree add "$WORKTREE" -b "$TICKET"
fi

# Pane 1: left — AI agent
tmux new-session -ds "$SESSION" -n "$WIN" -c "$WORKTREE"
tmux send-keys -t "$SESSION:$WIN.1" "claude -r" C-m

# Pane 2: right — scratch / notes
tmux split-window -h -t "$SESSION:$WIN" -c "$WORKTREE"

tmux select-layout -t "$SESSION:$WIN" main-vertical
tmux select-pane -t "$SESSION:$WIN.1"
attach_or_switch
