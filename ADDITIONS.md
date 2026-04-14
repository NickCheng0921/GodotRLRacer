# How to modify the project

## Making a new Track

1. Make a new scene, name doesn't matter

2. Generate a new set of points, add to path_points in the godot project root dir

3. Open tools/generate_path.gd, update the POINTS_FILE and WAYPOINT_COUNT, then right click and run the script
 - the following will be added: Path3D Node (track direction), CSGPolygon3D (a single tilable piece of road), Waypoints (Node3D) of collision shapes + labels for waypoints

4. Select the CSGPolygon3D, set editor to 3D view and bake a mesh and a collision shape
 - mesh is used for human to see road
 - collision shape is used to detect when we move off road (to reset the car)

5. Now we need to move these assets to the game scene
 - add a new Node3D for the track
    - baked mesh + the waypoints are a child of this Node3D
    - collision shape goes under an Area3D node w/ its collision layer set to 2, and add the Area3D to the `road` group
        - `road` group used to detect when we move off road, collision layer 2 to prevent car ray from hitting ground first