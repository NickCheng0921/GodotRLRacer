# GodotRLRacer

Goal is to create a racing agent w/ RL in a Godot Env

Godot handles the physics simulation, gdrl handles the RL + bridge between simulator and gym API

# Current Progress

Waypoint system in progress, still working on env. Demo below is human driven.

<img src="./assets/env_v1.01.gif" width=75% height=75%>

# To Run

```
1. Pull this project
2. Download Godot 4.6.2
3. Import godot_projects/racing-env-v-1/project.godot using the Godot engine import menu
4. Hit Run in the editor
```

# Planned Next Steps

**Environment**
- facelift: lighting, meshes, level scenery
- parallelized environment (multiple cars in one level + creation of a project executable to pass to gdrl)
- car flips since acceleration is too large currently
- add raycast sensors to car for RL observations
- map creation through curvilinear coords + script, currently manual using Path3D
    - greatly simplifies waypoint design for reward

**RL**
- model selection, currently using gdrl default
- reward function creation
    - waypoints, turning penalty, gas penalty, time