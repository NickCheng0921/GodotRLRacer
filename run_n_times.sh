#!/usr/bin/env bash
# Usage: ./run_n_times.sh [N]
# Runs train.py then visualize.py N times sequentially. N defaults to 1.
# Each train.py invocation auto-generates its own RACER_RUN_ID timestamp,
# so runs land in separate metrics/<run_id>/ directories.

set -u
cd "$(dirname "$0")"

N=${1:-1}
EXE="/c/Users/nicks/Documents/GodotRLRacer/godot_projects/racing-env-v-1/builds/racing_env_v1.exe"

for i in $(seq 1 "$N"); do
    echo
    echo "=========================================="
    echo "  Run $i / $N  ($(date))"
    echo "=========================================="

    # Generate the run ID here so we control it and can use it for renaming.
    RUN_ID=$(date +%Y%m%d_%H%M%S)
    export RACER_RUN_ID="$RUN_ID"

    python train.py --env_path "$EXE" --num_parallel 16 --speedup 16
    python visualize.py

    # Rename reward_plot.png to include the timestamp.
    if [ -f reward_plot.png ]; then
        mv reward_plot.png "reward_plot_${RUN_ID}.png"
        echo "Renamed reward_plot.png -> reward_plot_${RUN_ID}.png"
    else
        echo "Warning: reward_plot.png not found after run $i"
    fi
done

echo
echo "All $N runs complete."