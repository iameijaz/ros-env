# rosenv-setup

Stop manually sourcing ROS workspaces. One script sets everything up — then just `cd` and it works.

---

## The problem

Every ROS developer knows this pain:

```bash
# every. single. terminal.
source /opt/ros/jazzy/setup.bash # 
source ~/ros2_ws/install/local_setup.sh # cases when it's built from source
```

And when you have multiple workspaces across different distros, you either edit `.bashrc` back and forth or forget to source and spend ten minutes debugging why `ros2 topic list` isn't working.

## The solution

This script sets up [direnv](https://direnv.net/) to automatically source the correct ROS environment the moment you `cd` into a workspace — and unload it when you leave. No more manual sourcing. No global shell pollution. Each workspace is fully isolated.

---

## How it works

**Setup (once):**
```
ros_direnv_setup.sh
├── detects your shell (bash / zsh / fish)
├── detects your ROS installation (from env variables or asks you)
├── installs direnv if missing (or tells you how)
├── hooks direnv into your shell rc file
└── adds a ros-init function to your shell rc file
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
4. Install direnv and wire everything into your shell rc file

---

## Requirements

| Requirement | Notes |
|---|---|
| **bash** | The installer script runs with bash. Your daily shell can be anything — bash, zsh, or fish. Run it as `bash ros_direnv_setup.sh`, not `sh`. |
| **ROS** | Any distro, any installation method — apt, built from source, or custom path. ROS1 and ROS2 both work. |
| **sudo access** | Only needed if direnv is not yet installed. |
| **direnv** | Installed automatically by the script if missing. If auto-install fails, the script prints the manual install command for your OS. |

> **Note on shells:** The script itself must be run with bash (it uses bash-specific syntax). However it detects your current shell — bash, zsh, or fish — and writes the correct hook and `ros-init` syntax into the right rc file automatically.

---

## Shell support

| Shell | rc file written to | Supported |
|---|---|---|
| bash | `~/.bashrc` | ✓ |
| zsh | `~/.zshrc` | ✓ |
| fish | `~/.config/fish/config.fish` | ✓ |
| other | prompts you for the rc file path | ✓ |

---

## ROS compatibility

| Installation type | Detected via | Supported |
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

Safe to run multiple times. The script checks before writing — if direnv or `ros-init` is already in your shell rc file, it skips that step.

---

## License

MIT
