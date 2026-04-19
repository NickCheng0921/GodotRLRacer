# GodotRLRacer

Goal is to create a racing agent w/ reinforcement learning in a Godot Env

Godot handles the physics simulation, gdrl handles the RL + bridge between simulator and gym API

# Current Progress

Agent reward design in progress. RL Agent can learn to drive between waypoints reasonable well at 320K timesteps (313 updates).
 - agent observes: speed, loc of next 2 waypoints relative to self, whether we're on the ground

Below images show human driven + agent learning at different stages
 - notice how the 80k step agent has really jerky movements and constantly goes off track compared to 320k
 - agent rewards: moving closer to next waypoint, using throttle
 - agent penalties: flipping the car over, moving off track, moving away from next waypoint

<div style="display: flex;">
  <figure style="width: 50%; text-align: center;">
    <img src="./assets/env_v1.01.gif" width="33%">
    <figcaption>Human Driven, 1x speed</figcaption>
  </figure>

  <figure style="width: 50%; text-align: center;">
    <img src="./assets/agent_v1.gif" width="33%">
    <figcaption>RL Racing Agent, 4x speed, 80k timesteps</figcaption>
  </figure>

  <figure style="width: 50%; text-align: center;">
    <img src="./assets/agent_v1.01_320K.gif" width="33%">
    <figcaption>RL Racing Agent, 1x speed, 320k timesteps</figcaption>
  </figure>
</div>

# To play manually

```
1. Pull this project
2. Download Godot 4.6.2
3. Import godot_projects/racing-env-v-1/project.godot using the Godot engine import menu
4. Delete the Sync node in the Game scene
5. Hit Run in the editor
```

# Train + Inference

```
1. Run train.py then run the game
 - alternatively, export the game as an .exe and pass the path as a CLI arg for physics speedup
2. Once train is done, a `racer_ppo.zip will be made`, run inference.py to deploy your model onto the track
```

# Planned Next Steps

**Environment**
- facelift: lighting, meshes, level scenery
- parallelized environment (multiple cars in one level + creation of a project executable to pass to gdrl)
- add raycast sensors to car for RL observations

**RL**
- model selection, currently using gdrl default
- reward function creation
    - waypoints, turning penalty, gas penalty, time

# Waypoint generation

Waypoint generation is a mostly automated process to help expedite map creation

Paths are provided as (x,y,z) tuples in path_points/*.txt, and tools/generate_path.gd in the project turns them into a path3D + a CSGPolygon3D to provide the track w/ a mesh
 - non-parsable lines are skipped (lets us add comments)
 - the attached polygon can then be baked into a mesh (for human eyeballs) and a collision shape to keep track of whether the car's on the road
 - waypoint creation is done by sampling the curve at even intervals, first waypoint goes to first point in .txt