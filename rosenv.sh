#!/bin/bash
# rosenv.sh
# Detects your ROS installation, sets up direnv, and adds ros-init to ~/.bashrc

set -e

echo "==> Detecting ROS installation..."

# Try to find setup.bash from ROS env variables first
if [[ -n "$AMENT_PREFIX_PATH" ]]; then
  # ROS2 built from source: derive setup.bash from AMENT_PREFIX_PATH
  ROS_SETUP=$(echo "$AMENT_PREFIX_PATH" | cut -d':' -f1 | sed 's|/install.*|/install/setup.bash|')
  ROS_LOCAL=$(echo "$AMENT_PREFIX_PATH" | cut -d':' -f1 | sed 's|/install.*|/install/local_setup.sh|')
elif [[ -n "$ROS_DISTRO" ]]; then
  # System install via apt
  ROS_SETUP="/opt/ros/$ROS_DISTRO/setup.bash"
  ROS_LOCAL=""
fi

# Validate setup.bash
if [[ -z "$ROS_SETUP" ]] || [[ ! -f "$ROS_SETUP" ]]; then
  echo "    Could not detect ROS setup.bash automatically."
  read -rp "    Enter full path to your setup.bash: " ROS_SETUP
  if [[ ! -f "$ROS_SETUP" ]]; then
    echo "ERROR: File not found: $ROS_SETUP"
    exit 1
  fi
fi
echo "    setup.bash  -> $ROS_SETUP"

# Validate local_setup.sh — skip silently if not found from auto-detect
if [[ -n "$ROS_LOCAL" ]] && [[ ! -f "$ROS_LOCAL" ]]; then
  ROS_LOCAL=""
fi

if [[ -z "$ROS_LOCAL" ]]; then
  read -rp "    Enter full path to local_setup.sh (or press Enter to skip): " ROS_LOCAL
  if [[ -n "$ROS_LOCAL" ]] && [[ ! -f "$ROS_LOCAL" ]]; then
    echo "ERROR: File not found: $ROS_LOCAL"
    exit 1
  fi
fi

if [[ -n "$ROS_LOCAL" ]]; then
  echo "    local_setup -> $ROS_LOCAL"
else
  echo "    local_setup -> (none)"
fi

echo ""
echo "==> Installing direnv..."
sudo apt install -y direnv

echo "==> Hooking direnv into ~/.bashrc..."
if ! grep -q 'direnv hook bash' ~/.bashrc; then
  echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
  echo "    added direnv hook"
else
  echo "    already present, skipping"
fi

echo "==> Adding ros-init to ~/.bashrc..."
if ! grep -q 'ros-init' ~/.bashrc; then

  if [[ -n "$ROS_LOCAL" ]]; then
    ENVRC_BODY="source ${ROS_SETUP}\nsource ${ROS_LOCAL}"
  else
    ENVRC_BODY="source ${ROS_SETUP}"
  fi

  cat >> ~/.bashrc << EOF

# ros-init: run inside any ROS workspace to set up auto-sourcing
ros-init() {
  printf "${ENVRC_BODY}\n" > .envrc
  direnv allow
  echo "Done. cd out and back in to activate."
}
EOF
  echo "    added ros-init"
else
  echo "    already present, skipping"
fi

source ~/.bashrc

echo ""
echo "All done. To activate any new ROS workspace:"
echo "  cd ~/your_ws && ros-init"
