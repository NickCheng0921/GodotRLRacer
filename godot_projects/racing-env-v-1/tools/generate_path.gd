@tool
extends EditorScript

# ─────────────────────────────────────────────
#  Config — edit these before running
# ─────────────────────────────────────────────
const POINTS_FILE    := "res://path_points/copperstone_path.txt"  # path to your x y z file
const PATH_NODE_NAME := "GeneratedTrackPath"     # name given to the new Path3D node
const SMOOTH_TENSION := 0.5                 # Catmull-Rom tension  (0.0 = loose, 1.0 = tight)

const WAYPOINT_COUNT := 20
const WAYPOINT_HEIGHT := 5.0

# ─────────────────────────────────────────────

func _run() -> void:
	var points := _load_points(POINTS_FILE)
	if points.is_empty():
		push_error("generate_path: no points loaded from '%s'" % POINTS_FILE)
		return

	var curve := _build_curve(points)

	# ── Path3D ───────────────────────────────
	var path := Path3D.new()
	path.name = PATH_NODE_NAME
	path.curve = curve

	get_scene().add_child(path)
	path.owner = get_scene()

	# ── CSGPolygon3D (child of Path3D) ───────
	var csg := CSGPolygon3D.new()
	csg.name = "TrackMesh"

	# Set mode to PATH (enum value 2) and point it at our Path3D node
	csg.mode    = CSGPolygon3D.MODE_PATH
	csg.path_node = path.get_path()
	csg.path_joined = true # connects gaps in path
	# Make path phatter
	csg.polygon = PackedVector2Array([
		Vector2(-16.0,  0.0),
		Vector2(-16.0,  0.1),
		Vector2( 16.0,  0.1),
		Vector2( 16.0,  0.0),
	])

	path.add_child(csg)
	csg.owner = get_scene()
	
	print("generate_path: created '%s' with %d points + CSGPolygon3D track mesh." \
		% [PATH_NODE_NAME, points.size()])
	
	# Create waypoints
	_create_waypoints(path, get_scene())


# ── File loading ──────────────────────────────────────────────────────────────

func _load_points(file_path: String) -> Array[Vector3]:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("generate_path: cannot open file '%s'" % file_path)
		return []

	var points: Array[Vector3] = []

	while not file.eof_reached():
		var line := file.get_line().strip_edges()

		# skip blank lines and comments
		if line.is_empty() or line.begins_with("#"):
			continue

		# accept space-separated or comma-separated values
		var parts: PackedStringArray
		if "," in line:
			parts = line.split(",")
		else:
			parts = line.split(" ", false)   # false = skip empty tokens

		if parts.size() < 3:
			push_warning("generate_path: skipping malformed line: '%s'" % line)
			continue

		points.append(Vector3(
			float(parts[0].strip_edges()),
			float(parts[1].strip_edges()),
			float(parts[2].strip_edges())
		))

	file.close()
	return points


# ── Curve building (Catmull-Rom tangents) ─────────────────────────────────────

func _build_curve(points: Array[Vector3]) -> Curve3D:
	var curve := Curve3D.new()
	var n := points.size()

	for i in range(n):
		var pos := points[i]

		# Catmull-Rom: tangent at point i uses the neighbouring points.
		# At endpoints we clamp the phantom neighbour to the endpoint itself.
		var prev := points[max(i - 1, 0)]
		var next := points[min(i + 1, n - 1)]

		# The tangent vector scaled by tension and split into in/out handles.
		# Godot's add_point() wants *local* in/out offsets relative to the point.
		var tangent := (next - prev) * (SMOOTH_TENSION / 2.0)

		# in-handle  = direction arriving  at this point  (negate for Godot convention)
		# out-handle = direction departing from this point
		curve.add_point(pos, -tangent, tangent)

	return curve


func _create_waypoints(path: Path3D, scene_root: Node) -> void:
	var curve := path.curve
	var total_length := curve.get_baked_length()
	var spacing := total_length / WAYPOINT_COUNT

	var waypoints_root := Node3D.new()
	waypoints_root.name = "Waypoints"
	path.add_child(waypoints_root)        # add first
	waypoints_root.owner = scene_root     # owner after

	for i in range(WAYPOINT_COUNT):
		var offset := i * spacing
		var pos := curve.sample_baked(offset)
		pos.y += WAYPOINT_HEIGHT

		var wp := Area3D.new()
		wp.name = "Waypoint_%02d" % i
		wp.position = pos
		waypoints_root.add_child(wp)      # add first
		wp.owner = scene_root             # owner after

		var shape := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 4.0
		shape.shape = sphere
		shape.disabled = true # For Later
		wp.add_child(shape)               # add first
		shape.owner = scene_root
		
		var label := Label3D.new()
		label.text = "%02d" % i
		label.modulate = Color.RED
		label.pixel_size = 0.1
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED  # always faces camera
		wp.add_child(label)
		label.owner = scene_root
