#!/bin/bash
set -euo pipefail

source /usr/lib/limbo-backup/restore.defaults.bash
source /etc/limbo-backup/restore.conf.bash

# Show options and arguments
show_help() {
  echo "Usage: $0 [OPTIONS] <backup_archive_path>"
  echo ""
  echo "Options:"
  echo "  --apps app1,app2      Comma-separated list of apps to restore (optional; default is restore all apps)"
  echo "  --overwrite           Overwrite existing files during restore (optional; default is false)"
  echo "  --help                Show this help message and exit"
  echo ""
  echo "Arguments:"
  echo "  backup_archive_path   Path to the backup archive to restore (required). Supported schemas are: https://, http://, file:// or local filesystem path"
  echo "                        (e.g.  https://s3-server/backup.tar.gz, file:///tmp/backup.tar.gz.gpg, /tmp/archive.tar.gz)"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
  --help)
    show_help
    exit 0
    ;;
  --apps)
    IFS=',' read -ra RESTORE_APPS <<<"$2"
    shift 2
    ;;
  --overwrite)
    RESTORE_OVERWRITE="1"
    shift
    ;;
  -*)
    echo "Unknown option: $1"
    logger -p user.err -t "$LOGGER_TAG" "Unknown option: $1"
    show_help
    exit 1
    ;;
  *)
    export BACKUP_PATH="$1"
    shift
    ;;
  esac
done

# Check for required positional argument
if [[ -z "${BACKUP_PATH:-}" ]]; then
  echo "Error: backup_archive_path is required."
  logger -p user.err -t "$LOGGER_TAG" "Error: backup_path is required."
  show_help
  exit 1
fi

# Directory containing all backup modules
MODULES_DIR="/lib/limbo-backup/restore.modules.d"

logger -p user.debug -t "$LOGGER_TAG" "MODULES_DIR=$MODULES_DIR"

logger -p user.info -t "$LOGGER_TAG" "Starting module execution..."

if [[ ! -d "$MODULES_DIR" ]]; then
  logger -p user.err -t "$LOGGER_TAG" "Modules directory not found: $MODULES_DIR"
  exit 1
fi

mapfile -t MODULES < <(find "$MODULES_DIR" -type f -name '[0-9][0-9]-*.bash' | sort)

if [[ ${#MODULES[@]} -eq 0 ]]; then
  logger -p user.warn -t "$LOGGER_TAG" "No modules found in $MODULES_DIR"
  exit 0
fi

for MODULE in "${MODULES[@]}"; do

  MODULE_NAME=$(basename "$MODULE")

  logger -p user.info -t "$LOGGER_TAG" "Running module: $MODULE_NAME"

  START_TIME=$(date +%s)
  if ! bash "$MODULE"; then
    logger -p user.err -t "$LOGGER_TAG" "Module $MODULE_NAME failed"
    exit 1
  fi
  END_TIME=$(date +%s)
  DURATION=$((END_TIME - START_TIME))
  logger -p user.debug -t "$LOGGER_TAG" "Module $MODULE_NAME completed in ${DURATION}s"

done

logger -p user.info -t "$LOGGER_TAG" "All modules executed successfully."
