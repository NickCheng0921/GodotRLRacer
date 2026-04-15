# General Info for Godot

### Plugins

After adding in a plugin, it has to be enabled from Project -> Project Settings -> Plugins before being usable

### Waypoints

Default behavior of Godot w/ Nodes is to sort by their hash, not name

So waypoints 00 - 19 can return waypoint 18 as first, not waypoint 00

Remedy this w/ a custom sort, see _setup_waypoints() in Game.gd

### GodotRL Syncing

The Sync Node in the main game scene slows down loading if you want to play by hand
 - remove it and re-add it for training
 - if it can't be found, go to project -> project settings and re-enable the plugin