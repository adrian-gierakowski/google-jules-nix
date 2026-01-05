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
    echo "Nix not found. Installing using Native Nix installer..."

    # Pre-configure /etc/nix/nix.conf to ensure installation succeeds in container environments
    # (specifically disabling sandbox and filter-syscalls) and enabling requested features.
    if [ ! -d /etc/nix ]; then
        sudo mkdir -p /etc/nix
    fi

    # We overwrite/create nix.conf to ensure the installer picks up these settings.
    # The native installer generally respects existing configuration during the process.
    echo "sandbox = false" | sudo tee /etc/nix/nix.conf > /dev/null
    echo "filter-syscalls = false" | sudo tee -a /etc/nix/nix.conf > /dev/null
    echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf > /dev/null

    curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes

    # Source the nix profile to verify installation in this script
    if [ -e "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
else
    echo "Nix is already installed."
fi

RESTART_DAEMON=false

# Post-install configuration check
# The installer might overwrite /etc/nix/nix.conf, so we ensure our settings are present.
if [ -f /etc/nix/nix.conf ]; then
    if ! grep -q "sandbox = false" /etc/nix/nix.conf; then
        echo "Ensuring sandbox = false..."
        echo "sandbox = false" | sudo tee -a /etc/nix/nix.conf > /dev/null
        RESTART_DAEMON=true
    fi
    if ! grep -q "filter-syscalls = false" /etc/nix/nix.conf; then
        echo "Ensuring filter-syscalls = false..."
        echo "filter-syscalls = false" | sudo tee -a /etc/nix/nix.conf > /dev/null
        RESTART_DAEMON=true
    fi
    if ! grep -q "experimental-features = nix-command flakes" /etc/nix/nix.conf; then
        echo "Ensuring experimental-features = nix-command flakes..."
        echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf > /dev/null
        RESTART_DAEMON=true
    fi
else
    # Fallback if file is missing (unlikely)
    sudo mkdir -p /etc/nix
    echo "sandbox = false" | sudo tee /etc/nix/nix.conf > /dev/null
    echo "filter-syscalls = false" | sudo tee -a /etc/nix/nix.conf > /dev/null
    echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf > /dev/null
    RESTART_DAEMON=true
fi

# Apply custom configuration
if [ -n "$EXTRA_NIX_CONF" ]; then
    echo "Applying custom configuration..."

    # Ensure nix.custom.conf exists and is included in nix.conf
    # Check if nix.custom.conf exists, create if not
    if [ ! -f /etc/nix/nix.custom.conf ]; then
        echo "# Custom Nix configuration" | sudo tee /etc/nix/nix.custom.conf > /dev/null
    fi

    # Check if nix.conf includes nix.custom.conf
    if ! grep -q "nix.custom.conf" /etc/nix/nix.conf; then
        echo "Adding include for nix.custom.conf to nix.conf..."
        echo "" | sudo tee -a /etc/nix/nix.conf > /dev/null
        echo "!include nix.custom.conf" | sudo tee -a /etc/nix/nix.conf > /dev/null
        RESTART_DAEMON=true
    fi

    # Append the configuration to nix.custom.conf
    echo "$EXTRA_NIX_CONF" | sudo tee -a /etc/nix/nix.custom.conf > /dev/null

    RESTART_DAEMON=true
fi

if [ "$RESTART_DAEMON" = true ]; then
    echo "Restarting nix-daemon to apply changes..."
    if command -v systemctl &> /dev/null; then
         sudo systemctl restart nix-daemon || echo "Warning: Failed to restart nix-daemon."
    else
         echo "Warning: systemctl not found. You might need to restart nix-daemon manually."
    fi
fi

# Ensure nix-daemon is running and accessible
# In some container environments, systemd might report active but the socket is not visible.
echo "Verifying nix-daemon connection..."
SOCKET="/nix/var/nix/daemon-socket/socket"
if [ ! -S "$SOCKET" ]; then
    echo "Socket $SOCKET not found. Nix daemon might not be running correctly."

    # Try to start/restart
    if command -v systemctl &> /dev/null; then
         echo "Attempting restart via systemctl..."
         sudo systemctl restart nix-daemon || true
         sleep 2
    fi

    if [ ! -S "$SOCKET" ]; then
         echo "Socket still not found. Trying manual start..."
         if command -v systemctl &> /dev/null; then
            # Stop systemd service to avoid conflicts if it thinks it's running
            sudo systemctl stop nix-daemon nix-daemon.socket || true
         fi

         DAEMON_BIN="/nix/var/nix/profiles/default/bin/nix-daemon"
         if [ -x "$DAEMON_BIN" ]; then
             sudo "$DAEMON_BIN" --daemon > /var/log/nix-daemon.log 2>&1 &
             sleep 2
             if [ -S "$SOCKET" ]; then
                 echo "nix-daemon started manually."
             else
                 echo "Failed to start nix-daemon manually. Check /var/log/nix-daemon.log"
             fi
         else
             echo "Error: nix-daemon binary not found at $DAEMON_BIN."
         fi
    fi
else
    echo "nix-daemon socket found."
fi

# Configure specific nixpkgs commit if requested
if [ -n "$NIXPKGS_COMMIT" ]; then
    echo "Pinning nixpkgs to commit: $NIXPKGS_COMMIT"

    # Update the flake registry
    nix registry pin nixpkgs github:NixOS/nixpkgs/$NIXPKGS_COMMIT

    # Also set NIX_PATH for legacy commands if needed
    export NIX_PATH="nixpkgs=https://github.com/NixOS/nixpkgs/archive/$NIXPKGS_COMMIT.tar.gz:$NIX_PATH"

    echo "Nixpkgs pinned to $NIXPKGS_COMMIT in registry."
fi

echo "Setup complete!"
echo "---------------------------------------------------"
echo "Nix Version:"
nix --version
echo "---------------------------------------------------"

if [ -f /etc/nix/nix.conf ]; then
    echo "Current /etc/nix/nix.conf:"
    cat /etc/nix/nix.conf
    echo "---------------------------------------------------"
fi

if [ -f /etc/nix/nix.custom.conf ]; then
    echo "Current /etc/nix/nix.custom.conf:"
    cat /etc/nix/nix.custom.conf
    echo "---------------------------------------------------"
fi

# Check for user-level config
if [ -f "$HOME/.config/nix/nix.conf" ]; then
    echo "Current $HOME/.config/nix/nix.conf:"
    cat "$HOME/.config/nix/nix.conf"
    echo "---------------------------------------------------"
fi
