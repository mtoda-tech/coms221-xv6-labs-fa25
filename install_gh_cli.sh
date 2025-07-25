#!/usr/bin/env bash
#
# install_gh_cli.sh
#
# Installs GitHub CLI (gh) on Ubuntu or WSL using the official GitHub package repo.
#

set -euo pipefail

echo "=== Installing GitHub CLI (gh) ==="

# Ensure curl is available
if ! command -v curl >/dev/null 2>&1; then
  echo "Installing curl..."
  sudo apt update
  sudo apt install -y curl
fi

# Add GitHub CLI package repository
echo "Adding GitHub CLI repository..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
  sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
  sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# Update and install
echo "Updating package lists..."
sudo apt update

echo "Installing gh..."
sudo apt install -y gh

# Verify installation
echo "=== GitHub CLI Installed Successfully ==="
gh --version

echo "Next, authenticate GitHub CLI by running: gh auth login"

