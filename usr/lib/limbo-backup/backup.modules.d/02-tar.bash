#!/bin/bash
set -euo pipefail


# Load global config and user config
source /usr/lib/limbo-backup/backup.defaults.bash
source /etc/limbo-backup/backup.conf.bash

#
TAR_OUTPUT_PATH="$TAR_ARTEFACTS_DIR/${BACKUP_NAME}.tar.gz"


#
logger -p user.info -t "$LOGGER_TAG" "Starting TAR module execution..."


# Create output directory
mkdir -p "$TAR_ARTEFACTS_DIR"

# Ensure backup name is set
if [[ -z "${BACKUP_NAME:-}" ]]; then
  logger -p user.err -t "$LOGGER_TAG" "BACKUP_NAME is not set in backup.conf.bash"
  exit 1
fi


# Create archive
logger -p user.info -t "$LOGGER_TAG" "Creating archive: $TAR_OUTPUT_PATH"
tar -czf "$TAR_OUTPUT_PATH" -C "$RSYNC_ARTEFACTS_DIR" .


#
logger -p user.info -t "$LOGGER_TAG" "TAR module execution completed: $TAR_OUTPUT_PATH"
