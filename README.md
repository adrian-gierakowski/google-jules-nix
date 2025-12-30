# Google Jules Nix Setup

This repository contains a setup script `setup-nix.sh` to install and configure Nix in the Google Jules environment.

## Usage

1.  **Run the Setup Script**

    To install Nix with default settings (latest stable), simply run:

    ```bash
    ./setup-nix.sh
    ```

    This script will:
    -   Install Nix using the Determinate Systems installer (configured for container compatibility).
    -   Configure `nix.conf` with necessary settings (e.g., disabling sandboxing if needed).

2.  **Customizing the Installation**

    You can customize the installation by modifying the variables at the top of `setup-nix.sh` or by setting environment variables.

    -   **Pin specific nixpkgs commit:**
        To pin `nixpkgs` to a specific commit (e.g., for reproducibility):

        ```bash
        export NIXPKGS_COMMIT="6d6a82e3a039850b67793008937db58924679837"
        ./setup-nix.sh
        ```

    -   **Add custom nix.conf configuration:**
        To add extra configuration to `nix.conf`:

        ```bash
        export EXTRA_NIX_CONF="keep-outputs = true"
        ./setup-nix.sh
        ```

3.  **Using Nix**

    After installation, the script will source the necessary profile scripts. For new shell sessions, the Nix environment should be automatically available (setup by the installer in your profile).

## Creating a Custom Environment Snapshot

To persist your Nix installation and configuration across sessions in Google Jules, you should create a custom environment snapshot.

1.  **Run the Setup Script**: Ensure you have run `./setup-nix.sh` and verified your Nix setup is working as desired.
2.  **Create Snapshot**: Use the Google Jules interface or CLI to create a snapshot of your current environment.
    *   *Note: Refer to the specific Google Jules documentation for the "Create Snapshot" or "Save Image" action button in your workspace UI.*
3.  **Use Snapshot**: When starting a new session or workspace, select your custom snapshot. This will restore the environment with Nix already installed and configured.
