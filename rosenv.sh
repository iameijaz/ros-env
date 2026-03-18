#!/bin/bash
# rosenv.sh
# Detects your shell and ROS installation, sets up direnv, and adds ros-init to your rc file.
# Usage:
#   bash ros_direnv_setup.sh          → install
#   bash ros_direnv_setup.sh --uninstall → undo everything

set -e

# ── Guard: must run with bash ─────────────────────────────────────────────────
if [ -z "$BASH_VERSION" ]; then
  echo "ERROR: This script must be run with bash, not sh or another shell."
  echo "Run it as: bash ros_direnv_setup.sh"
  exit 1
fi

# ── Detect current shell and rc file ─────────────────────────────────────────
CURRENT_SHELL=$(basename "$SHELL")

case "$CURRENT_SHELL" in
  bash)
    RC_FILE="$HOME/.bashrc"
    HOOK_LINE='eval "$(direnv hook bash)"'
    ;;
  zsh)
    RC_FILE="$HOME/.zshrc"
    HOOK_LINE='eval "$(direnv hook zsh)"'
    ;;
  fish)
    RC_FILE="$HOME/.config/fish/config.fish"
    HOOK_LINE='direnv hook fish | source'
    ;;
  *)
    echo "WARNING: Unrecognised shell '$CURRENT_SHELL'. Supported: bash, zsh, fish."
    read -rp "    Enter your shell rc file path manually (or press Enter to abort): " RC_FILE
    if [[ -z "$RC_FILE" ]]; then
      echo "Aborted."
      exit 1
    fi
    HOOK_LINE='eval "$(direnv hook '"$CURRENT_SHELL"')"'
    ;;
esac

# ── Uninstall mode ────────────────────────────────────────────────────────────
if [[ "${1}" == "--uninstall" ]]; then
  echo "==> Uninstalling ros-direnv-setup..."
  echo "    Shell: $CURRENT_SHELL  →  $RC_FILE"
  echo ""

  if grep -q 'ros-init' "$RC_FILE" 2>/dev/null; then
    cp "$RC_FILE" "${RC_FILE}.bak"
    echo "    backed up $RC_FILE  →  ${RC_FILE}.bak"

    if [[ "$CURRENT_SHELL" == "fish" ]]; then
      sed -i '/# ros-init: run inside any ROS workspace/,/^end$/d' "$RC_FILE"
      sed -i '/# ros-fix: re-init a moved workspace/,/^end$/d' "$RC_FILE"
    else
      sed -i '/# ros-init: run inside any ROS workspace/,/^}$/d' "$RC_FILE"
      sed -i '/# ros-fix: re-init a moved workspace/,/^}$/d' "$RC_FILE"
    fi
    echo "    removed ros-init and ros-fix from $RC_FILE"
  else
    echo "    ros-init not found in $RC_FILE, skipping"
  fi

  if grep -q 'direnv hook' "$RC_FILE" 2>/dev/null; then
    sed -i '/direnv hook/d' "$RC_FILE"
    echo "    removed direnv hook from $RC_FILE"
  else
    echo "    direnv hook not found in $RC_FILE, skipping"
  fi

  echo ""
  read -rp "==> Remove .envrc files from all subdirectories of home? [y/n]: " REMOVE_ENVRC
  if [[ "$REMOVE_ENVRC" =~ ^[Yy]$ ]]; then
    COUNT=$(find "$HOME" -maxdepth 4 -name '.envrc' -exec grep -l 'ros' {} \; 2>/dev/null | wc -l)
    if [[ "$COUNT" -gt 0 ]]; then
      find "$HOME" -maxdepth 4 -name '.envrc' -exec grep -l 'ros' {} \; 2>/dev/null | while read -r f; do
        echo "    removing $f"
        rm "$f"
      done
    else
      echo "    no ROS-related .envrc files found"
    fi
  else
    echo "    skipping .envrc cleanup"
  fi

  echo ""
  read -rp "==> Uninstall direnv itself? [y/n]: " REMOVE_DIRENV
  if [[ "$REMOVE_DIRENV" =~ ^[Yy]$ ]]; then
    if command -v direnv &>/dev/null; then
      if sudo apt remove -y direnv 2>/dev/null; then
        echo "    direnv uninstalled"
      else
        echo "    could not auto-uninstall direnv. Remove it manually:"
        echo "      Ubuntu/Debian:  sudo apt remove direnv"
        echo "      Arch:           sudo pacman -R direnv"
        echo "      macOS:          brew uninstall direnv"
      fi
    else
      echo "    direnv is not installed, skipping"
    fi
  else
    echo "    keeping direnv"
  fi

  echo ""
  echo "Done. Restart your shell or run: source $RC_FILE"
  exit 0
fi

# ── Install mode ──────────────────────────────────────────────────────────────
echo "==> Detected shell: $CURRENT_SHELL  →  $RC_FILE"

# ── Detect ROS installation ───────────────────────────────────────────────────
echo ""
echo "==> Detecting ROS installation..."

if [[ -n "$AMENT_PREFIX_PATH" ]]; then
  ROS_SETUP=$(echo "$AMENT_PREFIX_PATH" | cut -d':' -f1 | sed 's|/install.*|/install/setup.bash|')
  ROS_LOCAL=$(echo "$AMENT_PREFIX_PATH" | cut -d':' -f1 | sed 's|/install.*|/install/local_setup.sh|')
elif [[ -n "$ROS_DISTRO" ]]; then
  ROS_SETUP="/opt/ros/$ROS_DISTRO/setup.bash"
  ROS_LOCAL=""
fi

if [[ -z "$ROS_SETUP" ]] || [[ ! -f "$ROS_SETUP" ]]; then
  echo "    Could not detect ROS setup.bash automatically."
  read -rp "    Enter full path to your setup.bash: " ROS_SETUP
  if [[ ! -f "$ROS_SETUP" ]]; then
    echo "ERROR: File not found: $ROS_SETUP"
    exit 1
  fi
fi
echo "    setup.bash  -> $ROS_SETUP"

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

# ── Check / install direnv ────────────────────────────────────────────────────
echo ""
echo "==> Checking direnv..."
if command -v direnv &>/dev/null; then
  echo "    already installed ($(direnv version))"
else
  echo "    direnv is not installed."
  read -rp "    Install it now? [y/n]: " INSTALL_DIRENV
  if [[ "$INSTALL_DIRENV" =~ ^[Yy]$ ]]; then
    if sudo apt install -y direnv 2>/dev/null; then
      echo "    direnv installed successfully"
    else
      echo ""
      echo "ERROR: Could not install direnv automatically."
      echo "Please install it manually and re-run this script:"
      echo ""
      echo "  Ubuntu/Debian:  sudo apt install direnv"
      echo "  Arch:           sudo pacman -S direnv"
      echo "  macOS:          brew install direnv"
      echo "  Other:          https://direnv.net/docs/installation.html"
      echo ""
      exit 1
    fi
  else
    echo ""
    echo "direnv is required. Install it manually and re-run this script:"
    echo ""
    echo "  Ubuntu/Debian:  sudo apt install direnv"
    echo "  Arch:           sudo pacman -S direnv"
    echo "  macOS:          brew install direnv"
    echo "  Other:          https://direnv.net/docs/installation.html"
    echo ""
    exit 1
  fi
fi

# ── Hook direnv into shell rc ─────────────────────────────────────────────────
echo ""
echo "==> Hooking direnv into $RC_FILE..."
if ! grep -q 'direnv hook' "$RC_FILE" 2>/dev/null; then
  echo "$HOOK_LINE" >> "$RC_FILE"
  echo "    added direnv hook"
else
  echo "    already present, skipping"
fi

# ── Add ros-init and ros-fix functions ────────────────────────────────────────
echo "==> Adding ros-init and ros-fix to $RC_FILE..."
if ! grep -q 'ros-init' "$RC_FILE" 2>/dev/null; then

  if [[ "$CURRENT_SHELL" == "fish" ]]; then
    cat >> "$RC_FILE" << 'EOF'

# ros-init: run inside any ROS workspace to set up auto-sourcing
# uses paths relative to the workspace so moving it never breaks
function ros-init
  set WSDIR (pwd)
  printf "WORKSPACE_DIR=\"%s\"\n[ -f \"\$WORKSPACE_DIR/install/setup.bash\" ] && source \"\$WORKSPACE_DIR/install/setup.bash\"\n[ -f \"\$WORKSPACE_DIR/install/local_setup.sh\" ] && source \"\$WORKSPACE_DIR/install/local_setup.sh\"\n" $WSDIR > .envrc
  direnv allow
  echo "Done. cd out and back in to activate."
end

# ros-fix: re-init a moved workspace — rewrites .envrc with correct current path
function ros-fix
  if not test -f .envrc
    echo "No .envrc found here. Run ros-init instead."
    return 1
  end
  ros-init
  echo "Fixed .envrc for "(pwd)
end
EOF
  else
    cat >> "$RC_FILE" << 'EOF'

# ros-init: run inside any ROS workspace to set up auto-sourcing
# uses paths relative to the workspace so moving it never breaks
ros-init() {
  cat > .envrc << ENVRC
WORKSPACE_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
[ -f "\$WORKSPACE_DIR/install/setup.bash" ] && source "\$WORKSPACE_DIR/install/setup.bash"
[ -f "\$WORKSPACE_DIR/install/local_setup.sh" ] && source "\$WORKSPACE_DIR/install/local_setup.sh"
ENVRC
  direnv allow
  echo "Done. cd out and back in to activate."
}

# ros-fix: re-init a moved workspace — rewrites .envrc with correct current path
ros-fix() {
  if [ ! -f .envrc ]; then
    echo "No .envrc found here. Run ros-init instead."
    return 1
  fi
  ros-init
  echo "Fixed .envrc for $(pwd)"
}

EOF
  fi

  echo "    added ros-init and ros-fix"
else
  echo "    already present, skipping"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "==> Reloading $RC_FILE..."
source "$RC_FILE" 2>/dev/null || true

echo ""
echo "All done. To activate any new ROS workspace:"
echo "  cd ~/your_ws && ros-init"
echo ""
echo "Moved a workspace and paths broke?"
echo "  cd ~/your_ws && ros-fix"
echo ""
echo "To undo everything later:"
echo "  bash ros_direnv_setup.sh --uninstall"
