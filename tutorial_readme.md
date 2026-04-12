Following guide at

https://github.com/edbeeching/godot_rl_agents/blob/main/docs/CUSTOM_ENV.md

Godot version: v4.1.stable.mono.official [970459615]

RL Plugin needs to be manually added from here

https://github.com/edbeeching/godot_rl_agents

Doesn't show up in asset store

Open project.godot and follow the guide to get started

### Thoughts on implementation

Guide isn't fully clear that the Sync node in the inherit for the Train scene isn't obviously from RL proj
 - looks like a regular node, just called Sync
 - need to expand it's script to find the parent owner

Unclear how to save an agent/exit cleanly after, might not be a part of guide