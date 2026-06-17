#!/usr/bin/env bash
# shellcheck shell=bash

_log_color() {
  local color="$1"; shift
  printf "\033[${color}m[%s]\033[0m %s\n" "$@"
}

log::ok()   { _log_color "0;32" "ok"   "$*"; }
log::skip() { _log_color "0;33" "skip" "$*"; }
log::warn() { _log_color "0;33" "warn" "$*"; }
log::info() { _log_color "0;34" "info" "$*"; }
log::err()  { _log_color "0;31" "err"  "$*" >&2; }
