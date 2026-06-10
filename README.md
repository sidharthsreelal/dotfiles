# Arch Linux Dotfiles & System Setup

This repository contains system configuration files (dotfiles), custom background scripts, and exported package lists to replicate this Arch Linux setup on a fresh machine.

## Repository Contents

*   `.config/` - Custom configurations for window managers, status bars, terminals, etc.
    *   `hypr/` - Hyprland window manager configurations, scripts, and wallpapers
    *   `waybar/` - Status bar configurations
    *   `kitty/`, `alacritty/`, `ghostty/`, `foot/` - Terminal setups
    *   `nvim/` - Neovim configurations
    *   `Code/User/settings.json` - VS Code settings
*   `home/` - Profile configurations placed directly in the home directory (`~`)
    *   `.bashrc`, `.bash_profile`, `.bash_logout`
    *   `.XCompose`
*   `scripts/` - Custom background and helper scripts
    *   `antigravity-sync-daemon.py` - File synchronization daemon
    *   `old_test_inotify.py`
    *   `remove_omarchy.sh`
*   `packages/` - Text files containing package lists for simple replication
    *   `pkglist.txt` - Native Arch packages (via Pacman)
    *   `foreignpkglist.txt` - AUR packages
*   `install.sh` - Standalone, manual, interactive installer script

---

## How to Install on a Fresh System

1.  **Clone this repository**:
    ```bash
    git clone <your-git-repository-url> ~/dotfiles
    cd ~/dotfiles
    ```

2.  **Execute the manual setup script**:
    ```bash
    ./install.sh
    ```

3.  **Confirm the prompt**:
    The script will ask for confirmation before modifying configurations or installing packages.

---

## Important Usage Notes

> [!WARNING]
> *   **Do NOT add `install.sh` to startup or reboot scripts**: This installer is designed to be executed **exactly once** upon setting up a new machine. It should **never** be configured to run automatically (e.g., in `.bashrc`, `.profile`, or window manager configs) as it may overwrite configuration changes and reinstall packages on every boot.
> *   **Interactive execution required**: For safety, the script checks if it's running in an interactive terminal. Non-interactive executions (such as automated startup agents) will fail automatically, preventing configuration reset cycles.
