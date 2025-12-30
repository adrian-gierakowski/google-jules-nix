# Google Jules Nix Setup

This repository contains a setup script `setup-nix.sh` to install and configure Nix in the Google Jules environment.

## Usage

1.  **Configure Environment in Google Jules**

    To use this script and persist the Nix installation across sessions, you must configure it as part of your repository's environment setup in the Google Jules interface.

    1.  Navigate to [jules.google.com](https://jules.google.com).
    2.  Select your repository from the **Codebases** list in the left sidebar.
    3.  Click on the **Configuration** tab at the top of the page.
    4.  In the **Initial Setup** section, add the following command:

        ```bash
        ./setup-nix.sh
        ```

    5.  Click the **Run and Snapshot** button.

    Google Jules will run the script, verify the output, and create a snapshot of the environment. This snapshot—with Nix installed and configured—will be automatically loaded for all future tasks and sessions for this repository.

2.  **Customizing the Installation**

    You can customize the installation by setting environment variables in the **Initial Setup** block before the script command.

    -   **Pin specific nixpkgs commit:**
        To pin `nixpkgs` to a specific commit (e.g., for reproducibility):

        ```bash
        export NIXPKGS_COMMIT="6d6a82e3a039850b67793008937db58924679837"
        ./setup-nix.sh
        ```

    -   **Add custom nix.conf configuration:**
        To add extra configuration to `nix.conf` (e.g., to keep build outputs):

        ```bash
        export EXTRA_NIX_CONF="keep-outputs = true"
        ./setup-nix.sh
        ```

3.  **Verifying the Setup**

    After the **Run and Snapshot** process completes, you can view the output logs in the Jules interface to verify that:
    -   Nix was installed successfully.
    -   The version info was printed.
    -   Your custom configuration was applied.
