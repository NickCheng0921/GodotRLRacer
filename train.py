from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv
from stable_baselines3 import PPO
from stable_baselines3.common.vec_env import VecMonitor
from stable_baselines3.common.callbacks import BaseCallback
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import argparse
import os
import time
from tqdm import tqdm

parser = argparse.ArgumentParser()
parser.add_argument("--env_path", default=None, help="Path to Godot binary (omit to use editor)")
parser.add_argument("--restore", default=None, help="Path to checkpoint to restore from")
parser.add_argument("--speedup", default=1, type=int)
parser.add_argument("--num_parallel", default=1, type=int)
parser.add_argument("--run_name", default=None, help="Run id for metrics dir; defaults to a timestamp")
args = parser.parse_args()

run_id = args.run_name or time.strftime("%Y%m%d_%H%M%S")
os.environ["RACER_RUN_ID"] = run_id
print(f"[train] RACER_RUN_ID={run_id}")


class RewardPlotCallback(BaseCallback):
    def __init__(self, total_timesteps, save_path="reward_plot.png"):
        super().__init__()
        self.save_path = save_path
        self.rewards = []
        self.timesteps = []
        self._pbar = tqdm(total=total_timesteps, unit="step", dynamic_ncols=True)
        # Track sim vs model update time
        self.sim_time = 0.0
        self.train_time = 0.0
        self._rollout_start_t = None
        self._rollout_end_t = None
        self._last_report_step = 0

    def _on_rollout_start(self):
        now = time.perf_counter()
        if self._rollout_end_t is not None:
            self.train_time += now - self._rollout_end_t
        self._rollout_start_t = now

    def _on_rollout_end(self):
        # Track simulation vs model update time
        now = time.perf_counter()
        self.sim_time += now - self._rollout_start_t
        self._rollout_end_t = now

        mean_reward = self.model.rollout_buffer.rewards.mean()
        self.rewards.append(mean_reward)
        self.timesteps.append(self.num_timesteps)

        total = self.sim_time + self.train_time
        sim_pct = 100 * self.sim_time / total if total > 0 else 0
        sps = (self.num_timesteps - self._last_report_step) / (now - self._rollout_start_t) if now > self._rollout_start_t else 0
        self._last_report_step = self.num_timesteps
        self._pbar.set_description(
            f"rew {mean_reward:.3f} | sim {sim_pct:.0f}% ({self.sim_time:.1f}s) train {100-sim_pct:.0f}% ({self.train_time:.1f}s) | {sps:.0f} sps"
        )
        self._pbar.update(self.num_timesteps - self._pbar.n)

    def _on_step(self) -> bool:
        return True

    def _on_training_end(self):
        self._pbar.close()
        n_updates = self.model.num_timesteps // (self.model.n_steps * self.model.n_envs)
        total = self.sim_time + self.train_time
        print(f"Training complete: {self.model.num_timesteps} timesteps, {n_updates} update steps")
        print(f"Sim time:   {self.sim_time:.1f}s ({100*self.sim_time/total:.1f}%)")
        print(f"Train time: {self.train_time:.1f}s ({100*self.train_time/total:.1f}%)")
        self._save_plot()

    def _save_plot(self):
        fig, ax = plt.subplots(figsize=(10, 4))
        ax.plot(self.timesteps, self.rewards, color="steelblue", linewidth=1.5, label="ep_rew_mean")
        ax.set_xlabel("Timesteps")
        ax.set_ylabel("Mean Episode Reward")
        ax.set_title("Training Reward")
        ax.legend()
        fig.tight_layout()
        fig.savefig(self.save_path)
        plt.close(fig)



env = StableBaselinesGodotEnv(env_path=args.env_path, speedup=args.speedup, n_parallel=args.num_parallel)
env = VecMonitor(env)

"""
python train.py --env_path /c/Users/nicks/Documents/GodotRLRacer/godot_projects/racing-env-v-1/builds/racing_env_v1.exe --num_parallel 1 --speedup 1024
"""

if args.restore:
    model = PPO.load(args.restore, env=env, device="auto")
    print(f"Restored from {args.restore}")
else:
    model = PPO(
        "MultiInputPolicy",
        env,
        n_steps=256,
        batch_size=1024,
        n_epochs=5,
        learning_rate=3e-4,
        ent_coef=0.005,
        verbose=0,
        tensorboard_log="logs/",
        #policy_kwargs=dict(net_arch=[512, 512]), # default 64, 64
        device="auto",
    )

# 500K took 841 sec on 8 parallel
# Try to hit 4k updates
total_timesteps = 20000
model.learn(total_timesteps=total_timesteps, callback=RewardPlotCallback(total_timesteps, save_path="reward_plot.png"))
model.save("racer_ppo")
env.close()
