#!/usr/bin/env bash
set -euo pipefail
cd /workspace/ASHENVEIL
export XDG_DATA_HOME=/workspace/ashen-runtime/data
export XDG_CONFIG_HOME=/workspace/ashen-runtime/config
export XDG_CACHE_HOME=/workspace/ashen-runtime/cache
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
godot --version
godot --headless --path . --editor --quit
XDG_DATA_HOME=/workspace/ashen-test/data XDG_CONFIG_HOME=/workspace/ashen-test/config XDG_CACHE_HOME=/workspace/ashen-test/cache godot --headless --path . res://tests/runner.tscn
