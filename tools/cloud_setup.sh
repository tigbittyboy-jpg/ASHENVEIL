#!/usr/bin/env bash
set -euo pipefail
cd /workspace/ASHENVEIL
export XDG_DATA_HOME=/workspace/ashen-runtime/data
export XDG_CONFIG_HOME=/workspace/ashen-runtime/config
export XDG_CACHE_HOME=/workspace/ashen-runtime/cache
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
godot --version
run_checked() {
  local task_log
  task_log=$(mktemp /tmp/ashen-check.XXXXXX)
  local task_status=0
  "$@" >"$task_log" 2>&1 || task_status=$?
  cat "$task_log"
  if rg -q '^(ERROR:|SCRIPT ERROR:)' "$task_log"; then task_status=1; fi
  rm "$task_log"
  return "$task_status"
}
run_checked godot --headless --path . --editor --quit
run_checked env XDG_DATA_HOME=/workspace/ashen-test/data XDG_CONFIG_HOME=/workspace/ashen-test/config XDG_CACHE_HOME=/workspace/ashen-test/cache godot --headless --path . res://tests/runner.tscn
run_checked env XDG_DATA_HOME=/workspace/ashen-boss-test/data XDG_CONFIG_HOME=/workspace/ashen-boss-test/config XDG_CACHE_HOME=/workspace/ashen-boss-test/cache godot --headless --path . res://tests/boss_playtest.tscn
python tools/check_audio.py
