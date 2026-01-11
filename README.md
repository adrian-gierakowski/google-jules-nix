# Google Jules Nix Setup

This repository contains a setup script `setup-nix.sh` to install and configure Nix in the Google Jules environment.

## Usage

1.  **Configure Environment in Google Jules**

    To use this script and persist the Nix installation across sessions, you must execute it as part of your repository's environment setup in the Google Jules interface.

    1.  Navigate to [jules.google.com](https://jules.google.com).
    2.  Select your repository from the **Codebases** list in the left sidebar.
    3.  Click on the **Environment** tab in the repository menu.
    4.  In the **Setup script** section, paste the following command:

        ```bash
        curl -sSL https://raw.githubusercontent.com/adrian-gierakowski/google-jules-nix/master/setup-nix.sh | bash
        ```

        or if you copied setup-nix.sh to your repository and commited to default branch:
        ```bash
        ./setup-nix.sh
        ```
        
    6.  Click the **Run and snapshot** button.

    Google Jules will run the script, verify the output, and create a snapshot of the environment. This snapshot—with Nix installed and configured—will be automatically loaded for all future tasks and sessions for this repository.

1.  **Customizing the Installation**

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
    curl -sSL https://raw.githubusercontent.com/adrian-gierakowski/google-jules-nix/master/setup-nix.sh | bash
    ```

2.  **Verifying the Setup**

    After the **Run and snapshot** process completes, you can view the output logs in the Jules interface to verify that:
    -   Nix was installed successfully.
    -   The version info was printed.
    -   Your custom configuration was applied.

3.  **Customizing Agent Environment**

    The agent operates within a persistent Bash session that sources standard shell configuration files. This allows you to customize the runtime environment for the agent and any processes it spawns (like `node`, `python`, etc.).

    To add custom environment variables, aliases, or functions, you can modify the `~/.bashrc` or `~/.profile` files in your home directory.

    For example, to ensure a specific environment variable is always available:

    ```bash
    echo 'export MY_CUSTOM_VAR="my_value"' >> ~/.bashrc
    ```

    Changes to `~/.bashrc` (for non-login shells) and `~/.profile` (for login shells) are automatically picked up by the agent's session. Note that only **exported** variables (`export VAR=...`) are inherited by child processes executed by the agent.
