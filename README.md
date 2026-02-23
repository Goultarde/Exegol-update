# ⚠️ WARNING: Beta version project!

This project is currently under development. 
# Exegol-update

## Overview

Exegol-update is a tool that facilitates the management, distribution, and automated loading of Exegol Docker images, via a modern client-server architecture based on Docker and Nginx.

## Prerequisites

- Linux system with administrator (root) rights
- [Exegol](https://github.com/ThePorgs/Exegol) installed on the server (used for building images)
- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/) installed

## Installation

### 1. Install Cronie, Docker, Docker Compose and add yourself to the docker group
```bash
sudo usermod -aG docker $USER
newgrp docker # temporary, it's better to restart the session
sudo systemctl enable docker --now
```

### 2. Install Exegol (on the server)

```bash
pipx install exegol
pipx ensurepath
exec [bash|zsh|...]
```

### 3. Clone this repository

```bash
git clone https://github.com/Goultarde/Exegol-update.git && cd Exegol-update
```




## Usage

### Configuration TUI

Exegol-update features a TUI (Terminal User Interface) to simplify configuration:

```bash
./exu.sh
```

This interface allows you to:

#### **Main menu**
```
╔══════════════════════════════════════════════════════════════╗
║                    EXEGOL-UPDATE SETUP                       ║
╚══════════════════════════════════════════════════════════════╝

Choose an option:

  1 - Setup and check environment
  2 - Server configuration
  3 - Client configuration
  4 - Build locally (Docker build only)
  5 - Uninstall server configuration
  6 - Exit

Use ↑↓ arrows or numbers (1-6) to navigate
Press 'q' to quit directly
```

#### **Available options**

- **1 - Setup and check environment**: Automatically checks and configures the environment
- **2 - Server configuration**: Launches `server/setup.sh` with an option for immediate build
- **3 - Client configuration**: Launches `client/initial_setup.sh` to configure the client
- **4 - Build locally (Docker build only)**: Builds the Exegol image locally without tar export
- **5 - Uninstall server configuration**: Removes the server setup (Docker container, cron task, bin)
- **6 - Exit**: Clean exit from the interface

#### **Navigation**
- **↑↓ arrows**: Navigate the menu
- **Numbers 1-6**: Direct selection
- **Enter**: Confirm selection
- **q**: Quick exit

### Automatic environment configuration

Option 1 (Setup and check environment) automatically performs:

- ✅ Exegol, Docker and Docker Compose verification
- ✅ Creation of `/exu` directory with correct permissions
- ✅ Creation of symlink to exegol in `/usr/local/bin/`
- ✅ Automatic acceptance of Exegol EULA
- ✅ Verification of server/client directories

### Server deployment workflow

Server deployment is done via the TUI (option 2) which automatically handles:

- Preparation of necessary directories to store images and logs
- Deployment of an Nginx server in a Docker container to expose `.tar` images
- Addition of a cron task to automate image management
- Option for immediate build for initial deployment

### Client usage

#### **Automatic configuration**
Client configuration is done via the TUI (option 3) which:

- Installs `exu-client` in `/usr/local/bin/` (globally accessible)
- Automatically configures the `/etc/hosts` file with the server's IP
- Creates the `exegol.update` entry to facilitate connection

#### **Using the client**
```bash
exu-client [options]
```

If no options are provided, exu-client automatically downloads and loads the latest available .tar image on the server, unless it's already present locally. A confirmation will be requested before any major action, unless --auto and/or --force modes are enabled.

#### Main options

- `--list, -l` : Lists available images on the server
- `--force, -f` : Forces download even if the file already exists
- `--load-only` : Loads a local image without contacting the server
- `--tag=[name:tag||tag]` : Re-tags the image after loading (valid formats: `name:tag` or `tag` only). By default, the tag is "FreeNightly" (modifiable in the code).
- `--auto, -a` : Automatic mode (no interaction required)
- `--server=[URL]` : Changes the server URL (format: `http://HOST:PORT` or `https://HOST:PORT`)
- `--check-commit` : Checks and displays if a new commit is available (based on Git hash)
- `-h, --help` : Displays detailed help

#### Usage examples

```bash
# Basic usage (default local server)
exu-client

# Connection to a remote server
exu-client --server=http://192.168.1.100:9000
exu-client --server=https://exegol-server.local:8443

# Usage with configured domain name
exu-client --server=http://exegol.update:9000

# Checking for new commits
exu-client --check-commit
exu-client --server=http://192.168.1.100:9000 --check-commit

# Combining options
exu-client --server=http://exegol.example.com:9000 --auto --force --tag=Nightly
exu-client --server=https://exu-prod.internal:8443 --list
```

## Architecture

- **Server**: Exposes Docker images via Nginx in a container, with automated management by cron.
- **Client**: Downloads, loads, and re-tags Docker images interactively or automatically.

## Server script: exu-server

The `exu-server` script (located in the `server/` folder) automates the following steps:
- Cloning or updating the Exegol images repository
- Building the Docker image according to the defined profile
- Exporting the image in `.tar` format into the shared folder
- Logging operations in a log file

### Available options

- `--debug` : Uses the Goultarde repository, main branch, light profile (test mode)
- `--force` : Forces the build even without a newly detected commit
- `--build-only` : Builds the image only, without exporting it or deleting anything
- `-h, --help` : Displays help and exits the script

### Automatic cleanup

The `exu-server` script automatically cleans up old `.tar` files:
- Removes all `.tar` files with the same prefix before creating the new one
- Prevents the accumulation of old files
- Keeps only the most recent file per profile

This script is normally launched automatically via a cron task (see the "Server deployment" section).

**It can also be executed manually at any time to force an immediate update:**

```bash
cd server
./exu-server [--force] [--debug] [--build-only]
```

This triggers the rebuilding and exporting of the image without waiting for the next scheduled execution.

### Checking for new commits

The `exu-client` client can quickly check if new commits are available without downloading images:

```bash
exu-client --check-commit
```

This command:
- Retrieves the latest commit hash from the server (`latest_commit.hash`)
- Compares it with the locally stored hash
- Displays `[+] New commit available` or `[-] No new commit`

This feature is useful for:
- Quickly checking the status of updates
- Automating checks in scripts
- Avoiding unnecessary downloads

## Advanced features

### Default port management

The `exu-client` client supports URLs without a specified port:
- **HTTP**: Default port 80
- **HTTPS**: Default port 443

```bash
# These commands are equivalent
exu-client --server=http://exegol.example.com:80
exu-client --server=http://exegol.example.com

# These commands are equivalent
exu-client --server=https://exegol.example.com:443
exu-client --server=https://exegol.example.com
```

### Automatic hash synchronization

The client automatically updates its local `latest_commit.hash` file after each successful download, ensuring accurate commit checks during future uses.
