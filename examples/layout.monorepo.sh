#!/usr/bin/env bash
# Example: monorepo layout — 4 panes
#   Pane 1 (left):         AI agent (claude -r) in the ticket worktree
#   Pane 2 (top-right):    secrets init script — staged, press Enter to run
#   Pane 3 (middle-right): companion service — git pull + start
#   Pane 4 (bottom-right): build in worktree — package manager install + build
#
# Copy to ~/.config/tmux/layout.sh and replace paths with your own.

set -euo pipefail

PROJECT_ROOT="${HOME}/dev/my-monorepo"
WORKTREE_BASE="${PROJECT_ROOT}/.worktrees"
COMPANION_REPO="${HOME}/dev/my-companion-service"
SHELL_HELPERS="${PROJECT_ROOT}/scripts/dev-helpers.sh"
SECRETS_CMD="bash ${PROJECT_ROOT}/scripts/secrets-init.sh"
BUILD_CMD="npm install && npm run build"

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
[[ -f "$SHELL_HELPERS" ]] && tmux send-keys -t "$SESSION:$WIN.1" "source $SHELL_HELPERS" C-m
tmux send-keys -t "$SESSION:$WIN.1" "claude -r" C-m

# Pane 2: top-right — secrets init (staged, awaiting Enter)
tmux split-window -h -t "$SESSION:$WIN" -c "$WORKTREE"
tmux send-keys -t "$SESSION:$WIN.2" "$SECRETS_CMD"

# Pane 3: middle-right — companion service
tmux split-window -v -t "$SESSION:$WIN" -c "$COMPANION_REPO"
tmux send-keys -t "$SESSION:$WIN.3" "git pull && npm start"

# Pane 4: bottom-right — build
tmux split-window -v -t "$SESSION:$WIN" -c "$WORKTREE"
tmux send-keys -t "$SESSION:$WIN.4" "$BUILD_CMD"

tmux select-layout -t "$SESSION:$WIN" main-vertical
tmux select-pane -t "$SESSION:$WIN.1"
attach_or_switch
