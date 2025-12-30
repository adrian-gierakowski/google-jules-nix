#!/bin/bash
set -e

# --- Configuration Section ---

# Set the specific nixpkgs commit hash here.
# Example: NIXPKGS_COMMIT="29e1732d84784a9e52504b8686d634208a53163e"
# Leave empty to use the default configuration.
NIXPKGS_COMMIT="${NIXPKGS_COMMIT:-}"

# Add custom nix.conf content here.
# Example: EXTRA_NIX_CONF="sandbox = false"
EXTRA_NIX_CONF="${EXTRA_NIX_CONF:-}"

# --- End Configuration Section ---

echo "Starting Nix setup..."

# Install Nix if not already installed
if ! command -v nix &> /dev/null; then
    echo "Nix not found. Installing using Determinate Systems installer..."
    # We disable sandbox and filter-syscalls to avoid issues in some container environments
    # The installer sets up /etc/nix/nix.conf and includes /etc/nix/nix.custom.conf
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm --extra-conf "sandbox = false" --extra-conf "filter-syscalls = false"

    # Source the nix profile to verify installation in this script
    if [ -e "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
else
    echo "Nix is already installed."
fi

# Apply custom configuration
if [ -n "$EXTRA_NIX_CONF" ]; then
    echo "Applying custom configuration..."

    # Ensure nix.custom.conf exists and is included in nix.conf
    # The DetSys installer usually creates nix.conf with "!include nix.custom.conf"

    # Check if nix.custom.conf exists, create if not
    if [ ! -f /etc/nix/nix.custom.conf ]; then
        echo "# Custom Nix configuration" | sudo tee /etc/nix/nix.custom.conf > /dev/null
    fi

    # Check if nix.conf includes nix.custom.conf
    if ! grep -q "nix.custom.conf" /etc/nix/nix.conf; then
        echo "Adding include for nix.custom.conf to nix.conf..."
        echo "" | sudo tee -a /etc/nix/nix.conf > /dev/null
        echo "!include nix.custom.conf" | sudo tee -a /etc/nix/nix.conf > /dev/null
    fi

    # Append the configuration to nix.custom.conf
    echo "$EXTRA_NIX_CONF" | sudo tee -a /etc/nix/nix.custom.conf > /dev/null

    echo "Restarting nix-daemon to apply changes..."
    if systemctl is-active --quiet nix-daemon; then
        sudo systemctl restart nix-daemon
    fi
fi

# Configure specific nixpkgs commit if requested
if [ -n "$NIXPKGS_COMMIT" ]; then
    echo "Pinning nixpkgs to commit: $NIXPKGS_COMMIT"

    # Update the flake registry
    nix registry pin nixpkgs github:NixOS/nixpkgs/$NIXPKGS_COMMIT

    # Also set NIX_PATH for legacy commands if needed
    # Note: This affects the current session. Persistent setting might require shell profile editing.
    # We will export it here for the verification step.
    export NIX_PATH="nixpkgs=https://github.com/NixOS/nixpkgs/archive/$NIXPKGS_COMMIT.tar.gz:$NIX_PATH"

    echo "Nixpkgs pinned to $NIXPKGS_COMMIT in registry."
fi

echo "Setup complete!"
echo "---------------------------------------------------"
echo "Nix Version:"
nix --version
echo "---------------------------------------------------"
if [ -f /etc/nix/nix.custom.conf ]; then
    echo "Current /etc/nix/nix.custom.conf:"
    cat /etc/nix/nix.custom.conf
    echo "---------------------------------------------------"
fi
