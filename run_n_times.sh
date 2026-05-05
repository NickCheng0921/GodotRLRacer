#!/usr/bin/env bash
# Usage: ./run_n_times.sh [N] [NUM_PARALLEL] [SPEEDUP]
# Runs train.py then visualize.py N times sequentially. N defaults to 1.
# All outputs are bundled into run_<uuid8>/.

set -u
cd "$(dirname "$0")"

N=${1:-1}
NUM_PARALLEL=${2:-16}
SPEEDUP=${3:-16}
EXE="/c/Users/nicks/Documents/GodotRLRacer/godot_projects/racing-env-v-1/builds/racing_env_v1.exe"
BUNDLE="run_$(python -c 'import uuid; print(str(uuid.uuid4())[:8])')"
mkdir -p "$BUNDLE"
echo "Bundle dir: $BUNDLE"

for i in $(seq 1 "$N"); do
    echo
    echo "=========================================="
    echo "  Run $i / $N  ($(date))"
    echo "=========================================="

    RUN_ID=$(date +%Y%m%d_%H%M%S)
    RUN_START=$(date +%s)
    TRAIN_LOG=$(mktemp)
    RACER_RUN_ID="$RUN_ID" python train.py --env_path "$EXE" --num_parallel "$NUM_PARALLEL" --speedup "$SPEEDUP" 2>&1 | tee "$TRAIN_LOG"
    RUN_END=$(date +%s)

    {
        echo "=== Run $i / $N  ($RUN_ID) ==="
        echo "num_parallel=$NUM_PARALLEL  speedup=$SPEEDUP"
        grep -E "^Training complete:|^Sim time:|^Train time:" "$TRAIN_LOG"
        echo "Total time: $((RUN_END - RUN_START))s"
        echo ""
    } >> "$BUNDLE/meta.txt"
    rm "$TRAIN_LOG"

    python visualize.py --out "$BUNDLE/${RUN_ID}_metrics.png"

    if [ -f reward_plot.png ]; then
        mv reward_plot.png "$BUNDLE/${RUN_ID}_reward_plot.png"
        echo "Moved reward_plot.png -> $BUNDLE/${RUN_ID}_reward_plot.png"
    else
        echo "Warning: reward_plot.png not found after run $i"
    fi
done

echo
echo "All $N runs complete. Outputs in $BUNDLE/"