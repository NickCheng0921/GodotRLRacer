# General Info for Godot

### Plugins

After adding in a plugin, it has to be enabled from Project -> Project Settings -> Plugins before being usable

### Waypoints

Default behavior of Godot w/ Nodes is to sort by their hash, not name

So waypoints 00 - 19 can return waypoint 18 as first, not waypoint 00

Remedy this w/ a custom sort, see _setup_waypoints() in Game.gd