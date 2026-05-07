#!/usr/bin/env bash
set -euo pipefail

METRICS_DIR="${APPDATA:-$HOME/.local/share/godot}/Godot/app_userdata/racing_env_v1/metrics"

if [ ! -d "$METRICS_DIR" ]; then
    echo "No metrics dir at: $METRICS_DIR"
    exit 0
fi

run_count=$(find "$METRICS_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l)
csv_count=$(find "$METRICS_DIR" -name "env_*.csv" | wc -l)
echo "Found $run_count run(s) / $csv_count csv(s) under: $METRICS_DIR"
rm -rf "$METRICS_DIR"/*
echo "Done."
