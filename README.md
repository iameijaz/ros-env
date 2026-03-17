# ros-env

Stop manually sourcing ROS workspaces. One script sets everything up — then just `cd` and it works.

---

## The problem

Every ROS developer knows this pain:

```bash
# every. single. terminal.
source /opt/ros/jazzy/setup.bash # [normal cases]
source ~/ros2_ws/install/local_setup.sh # [if build from source]
```

And when you have multiple workspaces across different distros, you either edit `.bashrc` back and forth or forget to source and spend ten minutes debugging why `ros2 topic list` isn't working.

## The solution

This script sets up [direnv](https://direnv.net/) to automatically source the correct ROS environment the moment you `cd` into a workspace — and unload it when you leave. No more manual sourcing. No global shell pollution. Each workspace is fully isolated.

---

## How it works

**Setup (once):**
```
ros_direnv_setup.sh
├── detects your ROS installation (from env variables or asks you)
├── installs direnv
├── hooks direnv into ~/.bashrc
└── adds a ros-init function to ~/.bashrc
```

**Per workspace (one command):**
```bash
cd ~/your_ws
ros-init
```

**After that, switching is just `cd`:**
```bash
cd ~/ros2_jazzy     # → jazzy environment loads
cd ~/ros2_humble    # → switches to humble automatically
cd ~                # → ROS environment unloads cleanly
```

---

## Installation

```bash
git clone https://github.com/yourusername/ros-direnv-setup
cd ros-direnv-setup
chmod +x ros_direnv_setup.sh
./ros_direnv_setup.sh
```

The script will:
1. Detect your ROS `setup.bash` from `$AMENT_PREFIX_PATH` or `$ROS_DISTRO` automatically
2. Ask you for the path if it cannot find it
3. Verify every path exists before writing anything
4. Install direnv and wire everything into your `~/.bashrc`

---

## Requirements

- Ubuntu / Debian-based Linux
- ROS 2 (any distro) — built from source or installed via apt
- bash

---

## Compatibility

| Installation type | Detected via | Works |
|---|---|---|
| ROS2 apt install | `$ROS_DISTRO` | ✓ |
| ROS2 built from source | `$AMENT_PREFIX_PATH` | ✓ |
| ROS1 (noetic) | `$ROS_DISTRO` | ✓ |
| Custom path | manual prompt | ✓ |

---

## After setup

For every new workspace you create:

```bash
cd ~/your_new_ws
ros-init
```

This drops a `.envrc` file into the workspace with your detected ROS paths, and trusts it with direnv. From that point on, the environment is managed automatically.

You can also commit `.envrc` to git — anyone on your team with direnv installed gets the same behaviour without any manual setup.

---

## Idempotent

Safe to run multiple times. The script checks before writing — if direnv or `ros-init` is already in your `.bashrc`, it skips that step.

---

## License

MIT
