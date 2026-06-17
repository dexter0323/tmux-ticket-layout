#!/usr/bin/env bash
# shellcheck shell=bash
# Interactive prompts — uses gum when available, falls back to read.
# Set TMUX_LAYOUT_NONINTERACTIVE=1 to skip all prompts and use env vars.

_prompt() {
  local var_name="$1"
  local question="$2"
  local default="${3:-}"

  if [[ -n "${!var_name:-}" ]]; then
    log::skip "$var_name already set: ${!var_name}"
    return
  fi

  if [[ "${TMUX_LAYOUT_NONINTERACTIVE:-}" == "1" ]]; then
    if [[ -n "$default" ]]; then
      printf -v "$var_name" '%s' "$default"
    fi
    return
  fi

  local hint=""
  [[ -n "$default" ]] && hint=" [default: $default]"

  if [[ "${GUM_UNAVAILABLE:-}" != "1" ]] && command -v gum >/dev/null 2>&1; then
    local val
    val=$(gum input --placeholder "${default}" --prompt "> " --header "${question}${hint}")
    [[ -z "$val" && -n "$default" ]] && val="$default"
    printf -v "$var_name" '%s' "$val"
  else
    local val
    read -r -p "${question}${hint}: " val
    [[ -z "$val" && -n "$default" ]] && val="$default"
    printf -v "$var_name" '%s' "$val"
  fi
}

_choose() {
  local var_name="$1"
  local question="$2"
  shift 2
  local options=("$@")

  if [[ -n "${!var_name:-}" ]]; then
    log::skip "$var_name already set: ${!var_name}"
    return
  fi

  if [[ "${TMUX_LAYOUT_NONINTERACTIVE:-}" == "1" ]]; then
    printf -v "$var_name" '%s' "${options[0]}"
    return
  fi

  if [[ "${GUM_UNAVAILABLE:-}" != "1" ]] && command -v gum >/dev/null 2>&1; then
    local val
    val=$(printf '%s\n' "${options[@]}" | gum choose --header "$question")
    printf -v "$var_name" '%s' "$val"
  else
    echo "$question"
    local i=1
    for opt in "${options[@]}"; do
      echo "  $i) $opt"
      ((i++))
    done
    local idx
    read -r -p "Choice [1]: " idx
    [[ -z "$idx" ]] && idx=1
    printf -v "$var_name" '%s' "${options[$((idx-1))]}"
  fi
}

_confirm() {
  local var_name="$1"
  local question="$2"
  local default="${3:-yes}"

  if [[ -n "${!var_name:-}" ]]; then
    log::skip "$var_name already set: ${!var_name}"
    return
  fi

  if [[ "${TMUX_LAYOUT_NONINTERACTIVE:-}" == "1" ]]; then
    printf -v "$var_name" '%s' "$default"
    return
  fi

  if [[ "${GUM_UNAVAILABLE:-}" != "1" ]] && command -v gum >/dev/null 2>&1; then
    if gum confirm "$question"; then
      printf -v "$var_name" '%s' "yes"
    else
      printf -v "$var_name" '%s' "no"
    fi
  else
    local ans
    read -r -p "$question (y/N): " ans
    case "$ans" in
      [Yy]*) printf -v "$var_name" '%s' "yes" ;;
      *)     printf -v "$var_name" '%s' "no"  ;;
    esac
  fi
}

prompts::gather() {
  echo ""
  log::info "Configuring your ticket layout — press Enter to accept defaults."
  echo ""

  # 1. Project root
  _prompt TMUX_LAYOUT_PROJECT_ROOT \
    "Path to your main git repository (absolute)" ""
  while [[ -z "${TMUX_LAYOUT_PROJECT_ROOT:-}" || ! -d "${TMUX_LAYOUT_PROJECT_ROOT/#\~/$HOME}/.git" ]]; do
    if [[ "${TMUX_LAYOUT_NONINTERACTIVE:-}" == "1" ]]; then
      log::err "TMUX_LAYOUT_PROJECT_ROOT must be set to a valid git repo path."
      exit 1
    fi
    log::warn "Not a git repo: ${TMUX_LAYOUT_PROJECT_ROOT:-<empty>}"
    TMUX_LAYOUT_PROJECT_ROOT=""
    _prompt TMUX_LAYOUT_PROJECT_ROOT \
      "Path to your main git repository (absolute)" ""
  done
  # Expand tilde
  TMUX_LAYOUT_PROJECT_ROOT="${TMUX_LAYOUT_PROJECT_ROOT/#\~/$HOME}"

  # 2. Worktree base
  _prompt TMUX_LAYOUT_WORKTREE_BASE \
    "Where should git worktrees be created?" \
    "${TMUX_LAYOUT_PROJECT_ROOT}/.worktrees"
  TMUX_LAYOUT_WORKTREE_BASE="${TMUX_LAYOUT_WORKTREE_BASE/#\~/$HOME}"

  # 3. Left-pane command
  _prompt TMUX_LAYOUT_PANE1_CMD \
    "Command to run in the main (left) pane" \
    "claude -r"

  # 4. Shell helpers (optional)
  _prompt TMUX_LAYOUT_SHELL_HELPERS \
    "Shell helpers file to source before the main command (leave blank to skip)" \
    ""

  # 5. Pane 2 command (top-right, staged)
  _prompt TMUX_LAYOUT_PANE2_CMD \
    "Command to stage in the top-right pane (press Enter to run it; blank for none)" \
    ""

  # 6. Pane 3 (optional middle-right)
  _confirm _WANT_PANE3 "Add a third pane (middle-right)?" "no"
  if [[ "${_WANT_PANE3}" == "yes" ]]; then
    _prompt TMUX_LAYOUT_PANE3_DIR \
      "Working directory for pane 3" \
      "${TMUX_LAYOUT_PROJECT_ROOT}"
    TMUX_LAYOUT_PANE3_DIR="${TMUX_LAYOUT_PANE3_DIR/#\~/$HOME}"
    _prompt TMUX_LAYOUT_PANE3_CMD \
      "Command to stage in pane 3 (blank for none)" \
      ""
  fi

  # 7. Pane 4 (optional bottom-right)
  _confirm _WANT_PANE4 "Add a fourth pane (bottom-right)?" "no"
  if [[ "${_WANT_PANE4}" == "yes" ]]; then
    _prompt TMUX_LAYOUT_PANE4_DIR \
      "Working directory for pane 4" \
      "${TMUX_LAYOUT_PROJECT_ROOT}"
    TMUX_LAYOUT_PANE4_DIR="${TMUX_LAYOUT_PANE4_DIR/#\~/$HOME}"
    _prompt TMUX_LAYOUT_PANE4_CMD \
      "Command to stage in pane 4 (blank for none)" \
      ""
  fi

  # 8. tmux.conf handling
  _choose TMUX_LAYOUT_TMUX_MODE \
    "How should we configure tmux?" \
    "a) Write full tmux.conf (recommended — Catppuccin theme, plugins, all settings)" \
    "b) Append prefix+W keybind only to my existing tmux.conf" \
    "c) Skip tmux.conf changes (I'll configure tmux myself)"
  # Normalize to a/b/c
  TMUX_LAYOUT_TMUX_MODE="${TMUX_LAYOUT_TMUX_MODE:0:1}"

  # 9. tw alias
  _confirm TMUX_LAYOUT_TW_ALIAS \
    "Add 'tw' alias to your shell config?  (tw <ticket-id> launches a session)" \
    "yes"
}
