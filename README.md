# Backup Tool

A simple and universal backup & restore tool for Docker Compose-based projects.

---

## Installation

### 1. Download the latest `.deb` release

Visit the [Releases](https://github.com/jordimock/backup-tool/releases) page and download the latest `.deb` package, or use:

```bash
wget https://github.com/jordimock/backup-tool/releases/download/v0.1/limbo-backup-tool_0.1_all.deb
```

> Replace the version if needed.

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
sudo dpkg -i limbo-backup-tool_0.1_all.deb
```

---

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
```

Modify values according to your environment.

> This file is treated as a conffile: it will not be overwritten or removed during package upgrades or uninstallation.

---

### Task definitions

Individual backup tasks are defined as configuration files in:

```
/etc/limbo-backup/rsync.conf.d/
```

Each file describes one backup job and **must follow the naming convention**:

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

---

### File format

Each task file should define the following variables:

```bash
CMD_BEFORE_BACKUP="docker compose --project-directory /docker/your-app stop"
CMD_AFTER_BACKUP="docker compose --project-directory /docker/your-app start"

INCLUDE_PATHS=(
  "/docker/your-app"
)

EXCLUDE_PATHS=(
  "/docker/your-app/tmp"
  "/docker/your-app/cache"
)
```

> You can define any number of `INCLUDE_PATHS` and `EXCLUDE_PATHS`.  
> `CMD_BEFORE_BACKUP` and `CMD_AFTER_BACKUP` are optional.

---

## Uninstall

To remove the package but keep the configuration:

```bash
sudo dpkg -r limbo-backup-tool
```

To completely purge the package and its configuration:

```bash
sudo dpkg --purge limbo-backup-tool
```

---

## Bakup usage

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

---

### Check logs

To inspect logs of the systemd timer or service:

```bash
journalctl -u limbo-backup.timer
journalctl -u limbo-backup.service
```

