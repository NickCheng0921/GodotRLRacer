extends Node
## Per-process episode metrics recorder.
##
## Writes one CSV row per episode to user://metrics/<run_id>/env_<pid>.csv.
## Run id comes from the RACER_RUN_ID env var (set by train.py); falls back to
## a timestamped "adhoc_" id when launched from the editor.
##
## Public API (call from Game.gd):
##   start_episode(track_name)            -- begin a new episode
##   tick(delta)                          -- accumulate sim time each physics frame
##   on_waypoint(new_idx, prev_idx, total, clean) -- detect lap rollover (clean = no off-road teleports during lap)
##   end_episode(reason)                  -- write the row, flush, deactivate

const SCHEMA := [
	"episode_id", "wall_clock_unix", "run_id", "env_pid", "track_name",
	"episode_sim_duration_s", "terminal_reason",
	"laps_completed", "completed_lap",
	"clean_laps_completed", "clean_completed_lap",
	"first_lap_s", "best_lap_s", "mean_lap_s",
	"best_clean_lap_s",
]

var _run_id: String
var _pid: int
var _file: FileAccess
var _episode_id: int = 0

var _active: bool = false
var _track_name: String = ""
var _episode_sim_s: float = 0.0
var _lap_sim_s: float = 0.0
var _lap_times: Array[float] = []
var _clean_lap_times: Array[float] = []


func _ready() -> void:
	_run_id = OS.get_environment("RACER_RUN_ID")
	if _run_id == "":
		_run_id = "adhoc_" + Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	_pid = OS.get_process_id()
	_open_file()


func start_episode(track_name: String) -> void:
	_track_name = track_name
	_episode_sim_s = 0.0
	_lap_sim_s = 0.0
	_lap_times.clear()
	_clean_lap_times.clear()
	_active = true


func tick(delta: float) -> void:
	if not _active:
		return
	_episode_sim_s += delta
	_lap_sim_s += delta


func on_waypoint(new_idx: int, prev_idx: int, total: int, clean: bool = false) -> void:
	if not _active:
		return
	# Lap completes when we wrap from the last waypoint back to index 0.
	if prev_idx == total - 1 and new_idx == 0:
		_lap_times.append(_lap_sim_s)
		if clean:
			_clean_lap_times.append(_lap_sim_s)
		_lap_sim_s = 0.0


func end_episode(reason: String) -> void:
	if not _active:
		return
	_active = false
	_episode_id += 1
	_write_row(reason)


func _open_file() -> void:
	var dir_path := "user://metrics/%s" % _run_id
	DirAccess.make_dir_recursive_absolute(dir_path)
	var path := "%s/env_%d.csv" % [dir_path, _pid]
	if not FileAccess.file_exists(path):
		var f_new := FileAccess.open(path, FileAccess.WRITE)
		f_new.store_csv_line(PackedStringArray(SCHEMA))
		f_new.close()
	_file = FileAccess.open(path, FileAccess.READ_WRITE)
	_file.seek_end()
	print("[MetricsRecorder] writing ", ProjectSettings.globalize_path(path))


func _write_row(reason: String) -> void:
	# Row schema (must match SCHEMA constant above):
	#   episode_id, wall_clock_unix, run_id, env_pid, track_name,
	#   episode_sim_duration_s, terminal_reason,
	#   laps_completed, completed_lap,
	#   first_lap_s, best_lap_s, mean_lap_s
	# Lap columns are empty strings when laps == 0 (parsed as NaN by pandas).
	var laps := _lap_times.size()
	var row := PackedStringArray()
	row.append(str(_episode_id))
	row.append("%.3f" % Time.get_unix_time_from_system())
	row.append(_run_id)
	row.append(str(_pid))
	row.append(_track_name)
	row.append("%.3f" % _episode_sim_s)
	row.append(reason)
	var clean_laps := _clean_lap_times.size()
	row.append(str(laps))
	row.append("1" if laps > 0 else "0")
	row.append(str(clean_laps))
	row.append("1" if clean_laps > 0 else "0")
	if laps == 0:
		row.append("")
		row.append("")
		row.append("")
	else:
		var first := _lap_times[0]
		var best := _lap_times[0]
		var total := 0.0
		for t in _lap_times:
			if t < best:
				best = t
			total += t
		row.append("%.3f" % first)
		row.append("%.3f" % best)
		row.append("%.3f" % (total / laps))
	if clean_laps == 0:
		row.append("")
	else:
		var best_clean := _clean_lap_times[0]
		for t in _clean_lap_times:
			if t < best_clean:
				best_clean = t
		row.append("%.3f" % best_clean)
	_file.store_csv_line(row)
	_file.flush()
