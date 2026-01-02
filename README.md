# Google Jules Nix Setup

This repository contains a setup script `setup-nix.sh` to install and configure Nix in the Google Jules environment.

## Quick Start

You can run the setup script directly from GitHub using `curl` and `bash`:

```bash
curl -sSL https://raw.githubusercontent.com/adrian-gierakowski/google-jules-nix/master/setup-nix.sh | bash
```

## Usage

1.  **Configure Environment in Google Jules**

    To use this script and persist the Nix installation across sessions, you must configure it as part of your repository's environment setup in the Google Jules interface.

    1.  Navigate to [jules.google.com](https://jules.google.com).
    2.  Select your repository from the **Codebases** list in the left sidebar.
    3.  Click on the **Environment** tab in the repository menu.
    4.  In the **Setup script** section, add the following command:

        ```bash
        ./setup-nix.sh
        ```

    5.  Click the **Run and snapshot** button.

    Google Jules will run the script, verify the output, and create a snapshot of the environment. This snapshot—with Nix installed and configured—will be automatically loaded for all future tasks and sessions for this repository.

2.  **Customizing the Installation**

    You can customize the installation by using the **Environment variables** section located below the **Setup script** editor.

    -   **Pin specific nixpkgs commit:**
        Add a new environment variable:
        *   **Key**: `NIXPKGS_COMMIT`
        *   **Value**: `6d6a82e3a039850b67793008937db58924679837` (or your desired commit hash)

    -   **Add custom nix.conf configuration:**
        Add a new environment variable:
        *   **Key**: `EXTRA_NIX_CONF`
        *   **Value**: `keep-outputs = true` (or your desired configuration)

    Alternatively, you can export these variables directly in the **Setup script** box before running the script:

    ```bash
    export NIXPKGS_COMMIT="6d6a82e3a039850b67793008937db58924679837"
    export EXTRA_NIX_CONF="keep-outputs = true"
    ./setup-nix.sh
    ```

3.  **Verifying the Setup**

    After the **Run and snapshot** process completes, you can view the output logs in the Jules interface to verify that:
    -   Nix was installed successfully.
    -   The version info was printed.
    -   Your custom configuration was applied.
