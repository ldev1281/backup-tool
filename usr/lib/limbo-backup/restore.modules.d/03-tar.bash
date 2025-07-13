#!/bin/bash
set -euo pipefail

#########################################################################

# Load global config and user config
source /usr/lib/limbo-backup/restore.defaults.bash
source /etc/limbo-backup/restore.conf.bash

# Ensure backup name is set
if [[ -z "${BACKUP_NAME:-}" ]]; then
  logger -p user.err -t "$LOGGER_TAG" "BACKUP_NAME is not set in restore.conf.bash"
  exit 1
fi

#
TAR_INPUT_PATH="$TAR_ARTEFACTS_DIR/${BACKUP_NAME}.tar.gz"

#########################################################################

#
logger -p user.info -t "$LOGGER_TAG" "Starting TAR module execution..."

#########################################################################

# Clear the destination directory
logger -p user.info -t "$LOGGER_TAG" "Clearing the destination directory: $RSYNC_ARTEFACTS_DIR"
rm -rf "$RSYNC_ARTEFACTS_DIR"/* "$RSYNC_ARTEFACTS_DIR"/.??* 2>/dev/null || true

#########################################################################

# Extract archive
logger -p user.info -t "$LOGGER_TAG" "Extracting archive: $TAR_INPUT_PATH"
tar -xzf "$TAR_INPUT_PATH" -C "$RSYNC_ARTEFACTS_DIR"

#########################################################################

#
logger -p user.info -t "$LOGGER_TAG" "TAR module execution completed: $TAR_INPUT_PATH → $RSYNC_ARTEFACTS_DIR"
