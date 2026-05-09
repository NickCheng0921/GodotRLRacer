"""Plot key metrics for a racing-env training run.

Usage:
    python visualize.py                       # latest run under default metrics root
    python visualize.py <run_id>              # specific run id (subdir under metrics/)
    python visualize.py --path <file_or_dir>  # explicit CSV file or run directory
    python visualize.py <run_id> --out plot.png

The default metrics root resolves Godot's `user://metrics/` to:
    %APPDATA%/Godot/app_userdata/racing_env_v1/metrics       (Windows)
    ~/.local/share/godot/app_userdata/racing_env_v1/metrics  (Linux/Mac)

Can open from Project -> Open user data folder
/c/Users/nicks/AppData/Roaming/Godot/app_userdata/racing_env_v1

/c/Users/nicks/AppData/Roaming/Godot/app_userdata/racing_env_v1/metrics/20260428_000931
"""

import argparse
import glob
import os
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


PROJECT_NAME = "racing_env_v1"


def default_metrics_root() -> Path:
    appdata = os.environ.get("APPDATA")
    if appdata:
        return Path(appdata) / "Godot" / "app_userdata" / PROJECT_NAME / "metrics"
    return (
        Path.home()
        / ".local"
        / "share"
        / "godot"
        / "app_userdata"
        / PROJECT_NAME
        / "metrics"
    )


def resolve_path(run_id, explicit):
    if explicit:
        return Path(explicit)
    root = default_metrics_root()
    if not root.exists():
        sys.exit(f"No metrics root: {root}")
    if run_id:
        return root / run_id
    runs = [p for p in root.iterdir() if p.is_dir()]
    if not runs:
        sys.exit(f"No runs in {root}")
    latest = max(runs, key=lambda p: p.stat().st_mtime)
    print(f"[visualize] using latest run: {latest.name}")
    return latest


def load(path: Path) -> pd.DataFrame:
    if path.is_file():
        df = pd.read_csv(path)
    elif path.is_dir():
        files = sorted(glob.glob(str(path / "env_*.csv")))
        if not files:
            sys.exit(f"No env_*.csv in {path}")
        df = pd.concat([pd.read_csv(f) for f in files], ignore_index=True)
    else:
        sys.exit(f"Not found: {path}")
    if df.empty:
        sys.exit(f"No episodes recorded yet in {path}")
    df = df.sort_values("wall_clock_unix").reset_index(drop=True)
    df["global_ep"] = df.index
    return df


def print_summary(df: pd.DataFrame) -> None:
    n = len(df)
    n_complete = int(df["completed_lap"].sum())
    total_laps = int(df["laps_completed"].sum())
    n_clean = int(df.get("clean_completed_lap", pd.Series(dtype=float)).fillna(0).sum())
    total_clean = int(df.get("clean_laps_completed", pd.Series(dtype=float)).fillna(0).sum())
    print(f"  episodes:        {n}")
    print(f"  with >=1 lap:    {n_complete} ({n_complete / n:.1%})")
    print(f"  with >=1 clean:  {n_clean} ({n_clean / n:.1%})")
    print(f"  total laps:      {total_laps}  (clean: {total_clean})")
    best = df["best_lap_s"].dropna()
    if not best.empty:
        print(f"  fastest lap:     {best.min():.3f} s")
        print(f"  median best:     {best.median():.3f} s")
    last = min(200, n)
    tail = df.tail(last)
    print(f"  last {last} eps:")
    print(f"    success rate:  {tail['completed_lap'].mean():.1%}")
    if "clean_completed_lap" in tail.columns:
        print(f"    clean rate:    {tail['clean_completed_lap'].fillna(0).mean():.1%}")
    tail_best = tail["best_lap_s"].dropna()
    if not tail_best.empty:
        print(f"    fastest lap:   {tail_best.min():.3f} s")


def plot(df: pd.DataFrame, out_path: Path, label: str) -> None:
    n = len(df)
    window = max(20, n // 50)

    fig, (ax1, ax2, ax3) = plt.subplots(3, 1, figsize=(11, 9), sharex=True)
    fig.suptitle(f"{label}  -  {n} episodes  (rolling window: {window})")

    success = df["completed_lap"].rolling(window, min_periods=1).mean()
    ax1.plot(df["global_ep"], success, color="steelblue", linewidth=1.5)
    ax1.set_ylabel("Success rate (any lap)")
    ax1.set_ylim(-0.02, 1.02)
    ax1.grid(alpha=0.3)

    if "clean_completed_lap" in df.columns:
        clean_success = (
            df["clean_completed_lap"].fillna(0).rolling(window, min_periods=1).mean()
        )
        ax3.plot(df["global_ep"], clean_success, color="seagreen", linewidth=1.5)
    else:
        ax3.text(
            0.5, 0.5, "no clean-lap data (older run)",
            ha="center", va="center", transform=ax3.transAxes,
            fontsize=12, color="gray",
        )
    ax3.set_ylabel("Clean lap success rate")
    ax3.set_ylim(-0.02, 1.02)
    ax3.set_xlabel("Global episode")
    ax3.grid(alpha=0.3)

    laps = df.dropna(subset=["best_lap_s"])
    if not laps.empty:
        ax2.scatter(
            laps["global_ep"],
            laps["best_lap_s"],
            s=8,
            alpha=0.3,
            color="gray",
            label="per-episode best",
        )
        rolling_min = df["best_lap_s"].rolling(window, min_periods=1).min()
        ax2.plot(
            df["global_ep"],
            rolling_min,
            color="firebrick",
            linewidth=1.5,
            label="rolling min",
        )
        ax2.legend(loc="upper right")
    else:
        ax2.text(
            0.5,
            0.5,
            "no laps completed yet",
            ha="center",
            va="center",
            transform=ax2.transAxes,
            fontsize=14,
            color="gray",
        )
    ax2.set_ylabel("Lap time (s, log)")
    ax2.set_yscale("log")
    ax2.grid(alpha=0.3, which="both")

    fig.tight_layout()
    fig.savefig(out_path, dpi=120)
    plt.close(fig)
    print(f"[visualize] saved {out_path}")


def main() -> None:
    p = argparse.ArgumentParser(
        description="Plot key metrics for a racing-env training run."
    )
    p.add_argument(
        "run_id",
        nargs="?",
        default=None,
        help="Run id (subfolder under metrics/). Omit to use latest.",
    )
    p.add_argument(
        "--path",
        default=None,
        help="Explicit path to a CSV file or run directory (overrides run_id).",
    )
    p.add_argument("--out", default=None, help="Output PNG path.")
    args = p.parse_args()

    path = resolve_path(args.run_id, args.path)
    df = load(path)
    label = path.stem if path.is_file() else path.name
    print(f"\nRun: {label}")
    print_summary(df)
    out = Path(args.out) if args.out else Path(f"{label}_metrics.png")
    plot(df, out, label)


if __name__ == "__main__":
    main()
