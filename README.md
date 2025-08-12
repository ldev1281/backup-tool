# Backup Tool

A simple and universal backup and restore tool for Docker Compose-based projects.

## What the backup contains

The raw backup created by the `rsync` module is stored under:

```
/var/lib/limbo-backup/artefacts/backup-rsync/
```

This directory is the **source** for archiving, encryption, and upload. It includes:

```
/
├── .limbo-backup/                               # Internal metadata snapshot (not part of user data)
│   ├── etc/
│   │   └── limbo-backup/                        # Backup of the full configuration directory
│   │       ├── rsync.conf.d/
│   │       │   └── 01-task-name.conf.bash       # Task definition used during backup
│   │       └── backup.conf.bash                 # Global backup configuration at the time of backup
│   │       └── restore.conf.bash                # Global restore configuration at the time of backup
│   └── usr/share/limbo-backup/VERSION           # Version of the backup tool used to create this backup
├── task-name/                                   # Data from the backup task named "task-name"
│   └── ...                                      # Files and directories from INCLUDE_PATHS, with full path preserved
```

### Explanation

- **`.limbo-backup/`**  
  This directory contains internal metadata used for recovery and audit. It ensures that the backup can be restored exactly, even if configuration files change in the future.

- **`task-name/`**  
  The directory name is derived from the filename `NN-task-name.conf.bash`. It contains all files defined by `INCLUDE_PATHS`, copied with full path preservation (`rsync -aR`).  
  See [Task definitions](#task-definitions) in the **Configuration** section for details.


### Example

If your task file is named:

```
01-outline.conf.bash
```

and contains:

```bash
INCLUDE_PATHS=(
  "/docker/outline"
)
```

Then the backup directory will contain:

```
/outline/
└── docker/outline/...
```

--- 

### 1. Download the latest .deb release

Visit the [Releases](https://github.com/ldev1281/backup-tool/releases) page and download the latest .deb package, or use:

```bash
wget -O limbo-backup.deb https://github.com/ldev1281/backup-tool/releases/download/v0.4/limbo-backup_v0.4_all.deb
```

> Replace the version if needed.

To automate latest version download run following command:

``` bash
VER=$(wget -qO- https://github.com/jordimock/backup-tool/releases/latest/download/VERSION)
wget -O limbo-backup.deb "https://github.com/ldev1281/backup-tool/releases/download/v${VER}/limbo-backup_v${VER}_all.deb"
```

### 2. Install dependencies

Make sure the required system packages are installed:

```bash
sudo apt-get update
sudo apt-get install -y \
  bash \
  tar \
  gzip \
  gnupg \
  rclone \
  systemd \
  coreutils \
  rsync \
  openssh-client
```

### 3. Install the package

```bash
sudo dpkg -i limbo-backup.deb
```

### 4. Post-installation check

To confirm that the systemd timer is active:

```bash
systemctl status limbo-backup.timer
```

---

## Configuration

### Main configuration file

Global settings are defined in:

```
/etc/limbo-backup/backup.conf.bash
/etc/limbo-backup/restore.conf.bash
```

Modify values according to your environment.

> This file is treated as a conffile: it will not be overwritten or removed during package upgrades or uninstallation.


### Task definitions

Individual backup tasks are defined as configuration files in:

```
/etc/limbo-backup/rsync.conf.d/
```

Each file describes one backup/restore job and **must follow the naming convention**:

```
NN-name.conf.bash
```

Where:

- `NN` — a two-digit number that determines execution order (e.g. `01`, `10`, `99`)
- `name` — any identifier for the task (e.g. `database`, `outline`, `media`)
- `*.conf.bash` — required extension, all files must be readable Bash scripts

All tasks are executed **in alphanumeric order**, based on the `NN-` prefix.

**Example filenames:**

- `01-example.conf.bash`
- `10-outline-app.conf.bash`
- `99-media.conf.bash`

Only files that match this pattern and are executable will be processed.

### Task file format

Each task file should define the following variables:

```bash
CMD_BEFORE_BACKUP="docker compose --project-directory /docker/your-app stop"
CMD_AFTER_BACKUP="docker compose --project-directory /docker/your-app start"
CMD_BEFORE_RESTORE="docker compose --project-directory /docker/your-app stop"
CMD_AFTER_RESTORE="docker compose --project-directory /docker/your-app start"

INCLUDE_PATHS=(
  "/docker/your-app"
)

EXCLUDE_PATHS=(
  "/docker/your-app/tmp"
  "/docker/your-app/cache"
)
```

> You can define any number of `INCLUDE_PATHS` and `EXCLUDE_PATHS`.  
> `CMD_BEFORE_BACKUP`, `CMD_AFTER_BACKUP`, `CMD_BEFORE_RESTORE` and `CMD_AFTER_RESTORE` are optional.

---

## Backup usage

### Manual backup

To run all configured backup tasks immediately:

```bash
sudo systemctl start limbo-backup.service
```

This will:

1. Load global configuration from `/etc/limbo-backup/backup.conf.bash`
2. Execute all task files from `/etc/limbo-backup/rsync.conf.d/` in alphanumeric order
3. Apply all enabled plugins (e.g., rsync, tar, gpg, rclone)

Logs are written to `journalctl` via systemd when executed as a service.


### Check logs

To inspect logs of the systemd timer or service:

```bash
journalctl -u limbo-backup.timer
journalctl -u limbo-backup.service
```
---

## Restore usage

### Manual restore

To run all configured restore tasks immediately:

```bash
sudo limbo-restore.bash [OPTIONS] <backup_archive_path>
```

This will:

1. Set lock to prevent simultaneous execution
2. Load global configuration from `/etc/limbo-backup/restore.conf.bash`
3. Execute all task files from `/etc/limbo-backup/rsync.conf.d/` in alphanumeric order
4. Apply all enabled plugins (e.g., rsync, tar, gpg, curl)

Logs are written to `journalctl` via systemd when executed as a service.

### Restore Options and Arguments

| Option         | Required | Description | Example |
|----------------|----------|-------------|---------|
| `--apps`       | Optional | Specify a comma-separated list of applications to restore from the backup. By default, all applications will be restored. | `--apps keycloak,wekan` |
| `--no-keep-local`  | Optional | By default, all files and directories to be overwritten or deleted are first backed up to the `RESTORE_ARCHIVES_DIR` directory. You can disable this behavior with with option.| `--no-keep-local` |

| Argument       | Required | Description | Example |
|----------------|----------|-------------|---------|
| `backup_archive_path` | Yes | Path to the backup archive to restore. Supported schemas are: https://, http://, file:// or local filesystem path | `https://s3-server/backup.tar.gz`<br> `file:///tmp/backup.tar.gz.gpg`<br>`/tmp/archive.tar.gz` |


### Check logs

To inspect logs of the systemd timer or service:

```bash
journalctl -u limbo-backup.timer
journalctl -u limbo-backup.service
```
---

## Uninstall

To remove the package but keep the configuration:

```bash
sudo dpkg -r limbo-backup
```

To completely purge the package and its configuration:

```bash
sudo dpkg --purge limbo-backup
```
