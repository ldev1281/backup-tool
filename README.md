# Backup Tool

A simple and universal backup & restore tool for Docker Compose-based projects.

This tool consists of three main files:

1. `backup.bash` - creates backups of your project data and configuration.
2. `restore.bash` - restores your project data from a backup archive.
3. `backup-tool.config.bash` - example configuration file you can adapt for your project.

---

## Project Structure Example

```
your-project/
├── docker-compose.yml
├── backups/                     # Backups are stored here
├── backup-tool/                 # Git submodule (this tool)
│   ├── backup.bash
│   ├── restore.bash
│   └── backup-tool.config.bash  # Example configuration
└── backup-tool.config.bash      # Your actual config for backups (project specific)
```

---

## Installation

1. Add the `backup-tool` submodule manually to your project by editing the `.gitmodules` file. Create the file if it doesn’t exist and add the following:

   ```ini
   [submodule "backup-tool"]
       path = backup-tool
       url = https://github.com/jordimock/backup-tool.git
   ```


2. Create a configuration file named `backup-tool.config.bash` in the root of your project.

   Define the following variables inside:

   - `TO_BACKUP` — an array of directories or files you want to backup (relative to your project root).
   - `GPG_FINGERPRINT` — (optional) the fingerprint of your GPG key if you want to encrypt your backups.

   Example:
   ```bash
   TO_BACKUP=(
       ".env"
       "vol"
   )

   GPG_FINGERPRINT="YOUR-GPG-FINGERPRINT-HERE"
   ```

---

## Usage

> All commands must be run from the root of your project.

### Create a backup
```bash
./backup-tool/backup.bash
```

### Restore from a backup
```bash
./backup-tool/restore.bash /path/to/backup-file.tar.gz
```

### Restore from an encrypted backup
```bash
./backup-tool/restore.bash /path/to/backup-file.gpg
```

---

## How it works

- The tool reads your project’s configuration from `backup-tool.config.bash`, located in the root of your project.
- Backups are saved in the `backups/` folder at the root level.
- Supports optional GPG encryption of your backup archives.

---
