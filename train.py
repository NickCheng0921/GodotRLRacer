from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv
from stable_baselines3 import PPO
from stable_baselines3.common.vec_env import VecMonitor
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--env_path", default=None, help="Path to Godot binary (omit to use editor)")
parser.add_argument("--restore", default=None, help="Path to checkpoint to restore from")
parser.add_argument("--speedup", default=16, type=int)
args = parser.parse_args()

env = StableBaselinesGodotEnv(env_path=args.env_path, speedup=args.speedup)
env = VecMonitor(env)

if args.restore:
    model = PPO.load(args.restore, env=env)
    print(f"Restored from {args.restore}")
else:
    model = PPO(
        "MultiInputPolicy",
        env,
        n_steps=1024,
        batch_size=64,
        n_epochs=10,
        learning_rate=3e-4,
        ent_coef=0.001,
        verbose=1,
        tensorboard_log="logs/",
    )

model.learn(total_timesteps=1_000_000)
model.save("racer_ppo")
env.close()
