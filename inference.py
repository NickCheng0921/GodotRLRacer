from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv
from stable_baselines3 import PPO
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--env_path", default=None, help="Path to Godot binary (omit to use editor)")
parser.add_argument("--model", default="racer_ppo", help="Path to saved model (without .zip)")
parser.add_argument("--speedup", default=1, type=int)
args = parser.parse_args()

env = StableBaselinesGodotEnv(env_path=args.env_path, speedup=args.speedup)
model = PPO.load(args.model, env=env)
print(f"Loaded model from {args.model}.zip")

obs = env.reset()
while True:
    action, _ = model.predict(obs, deterministic=True)
    obs, reward, done, info = env.step(action)
