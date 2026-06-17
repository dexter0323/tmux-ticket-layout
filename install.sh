#!/usr/bin/env bash
# tmux-ticket-layout installer
# Usage: bash install.sh
# Curl-pipe: curl -fsSL https://gitlab.com/juan.sanchez.ctr/tmux-ticket-layout/-/raw/main/install.sh | bash
#
# Environment variables (set to skip interactive prompts):
#   TMUX_LAYOUT_NONINTERACTIVE=1       Skip all gum prompts; use env vars + defaults
#   TMUX_LAYOUT_PROJECT_ROOT           Absolute path to your main git repo (required)
#   TMUX_LAYOUT_WORKTREE_BASE          Where worktrees are created (default: $PROJECT_ROOT/.worktrees)
#   TMUX_LAYOUT_PANE1_CMD              Main pane command (default: claude -r)
#   TMUX_LAYOUT_SHELL_HELPERS          Shell helpers file to source in pane 1 (optional)
#   TMUX_LAYOUT_PANE2_CMD              Top-right pane staged command (optional)
#   TMUX_LAYOUT_PANE3_DIR / _CMD       Middle-right pane (optional)
#   TMUX_LAYOUT_PANE4_DIR / _CMD       Bottom-right pane (optional)
#   TMUX_LAYOUT_TMUX_MODE              a=full write, b=keybind only, c=skip (default: a)
#   TMUX_LAYOUT_TW_ALIAS               Add tw alias: yes/no (default: yes)

set -euo pipefail

REPO_URL="https://gitlab.com/juan.sanchez.ctr/tmux-ticket-layout"

# ── Phase 0: curl-pipe bootstrap ──────────────────────────────────────────────
# When piped through bash, BASH_SOURCE[0] is empty, "bash", or "-".
# Clone the repo to a temp dir and re-exec from there so lib/ is available.
if [[ "${BASH_SOURCE[0]:-}" == "" || "${BASH_SOURCE[0]:-}" == "bash" || "${BASH_SOURCE[0]:-}" == "-" ]]; then
  TMPDIR_CLONE="$(mktemp -d)"
  echo "[info] Cloning tmux-ticket-layout into ${TMPDIR_CLONE} ..."
  git clone --depth=1 "$REPO_URL" "${TMPDIR_CLONE}/tmux-ticket-layout"
  exec bash "${TMPDIR_CLONE}/tmux-ticket-layout/install.sh" "$@"
fi

INSTALL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Load lib modules ───────────────────────────────────────────────────────────
# shellcheck source=lib/log.sh
source "${INSTALL_ROOT}/lib/log.sh"
# shellcheck source=lib/checks.sh
source "${INSTALL_ROOT}/lib/checks.sh"
# shellcheck source=lib/prompts.sh
source "${INSTALL_ROOT}/lib/prompts.sh"
# shellcheck source=lib/write.sh
source "${INSTALL_ROOT}/lib/write.sh"

# ── Phase 1: dependency checks ────────────────────────────────────────────────
log::info "tmux-ticket-layout installer"
echo ""
checks::os
checks::ensure_git
checks::ensure_tmux
checks::ensure_tpm
checks::ensure_gum

# ── Phase 2: interactive prompts ──────────────────────────────────────────────
prompts::gather

# ── Phase 3: write files ──────────────────────────────────────────────────────
echo ""
log::info "Writing files..."

write::layout_sh
write::tmux_files

case "${TMUX_LAYOUT_TMUX_MODE:-a}" in
  a) write::tmux_conf_full ;;
  b) write::tmux_conf_keybind_only ;;
  c) log::skip "Skipping tmux.conf changes (mode c)" ;;
esac

if [[ "${TMUX_LAYOUT_TW_ALIAS:-yes}" == "yes" ]]; then
  write::tw_alias
fi

# ── Phase 4: summary ──────────────────────────────────────────────────────────
echo ""
log::ok "Installation complete!"
echo ""
echo "  layout.sh  →  ~/.config/tmux/layout.sh"
echo "  project    →  ${TMUX_LAYOUT_PROJECT_ROOT}"
echo "  worktrees  →  ${TMUX_LAYOUT_WORKTREE_BASE}"
echo ""
echo "Next steps:"
echo "  1.  source ~/.zshrc           (or open a new terminal)"
echo "  2.  tmux                      (start a tmux session)"
echo "  3.  prefix + I                (Ctrl-a then Shift-I — install plugins, first time only)"
echo "  4.  tw TICKET-123             (launch a ticket session)"
echo "      OR: inside tmux, prefix + W, type the ticket ID"
echo ""
