#!/usr/bin/env bash
# shellcheck shell=bash

checks::os() {
  case "$(uname -s)" in
    Darwin) ;;
    Linux)  log::warn "Linux detected — pbcopy is macOS-only; clipboard copy in tmux will not work without xclip/xsel" ;;
    *)      log::warn "Unrecognised OS $(uname -s) — proceeding anyway" ;;
  esac
}

checks::ensure_git() {
  if ! command -v git >/dev/null 2>&1; then
    log::err "git is required but not found. Install it and re-run."
    exit 1
  fi
}

checks::ensure_tmux() {
  if command -v tmux >/dev/null 2>&1; then
    log::skip "tmux already installed ($(tmux -V))"
    return
  fi
  log::info "tmux not found — attempting to install"
  if command -v brew >/dev/null 2>&1; then
    brew install tmux
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get install -y tmux
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y tmux
  else
    log::err "Cannot auto-install tmux. Install it manually then re-run."
    exit 1
  fi
}

checks::ensure_tpm() {
  local tpm_dir="${HOME}/.tmux/plugins/tpm"
  if [[ -d "$tpm_dir" ]]; then
    log::skip "TPM already present at $tpm_dir"
    return
  fi
  log::info "Cloning TPM into $tpm_dir"
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$tpm_dir"
  log::ok "TPM cloned — inside tmux run: prefix + I  to install plugins"
}

checks::ensure_gum() {
  if command -v gum >/dev/null 2>&1; then
    log::skip "gum already installed"
    return
  fi
  log::info "gum not found — attempting to install (used for interactive prompts)"
  if command -v brew >/dev/null 2>&1; then
    brew install gum
  else
    log::warn "gum not available and Homebrew not found. Falling back to plain read prompts."
    export GUM_UNAVAILABLE=1
  fi
}
