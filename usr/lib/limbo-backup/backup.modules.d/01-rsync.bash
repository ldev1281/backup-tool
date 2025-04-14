#!/bin/bash
set -euo pipefail

# Load global backup configuration
source /etc/limbo-backup/backup.conf.bash

logger -p user.info -t "$LOGGER_TAG" "Starting RSYNC module execution..."

# Find all matching config files and sort by name
mapfile -t RSYNC_CONFIG_FILES < <(find "$RSYNC_CONFIG_DIR" -type f -name '[0-9][0-9]-*.conf.bash' | sort)

# 
for CONFIG in "${RSYNC_CONFIG_FILES[@]}"; do
  CONFIG_FILENAME="$(basename "$CONFIG")"
  ARTEFACT_NAME="${CONFIG_FILENAME#*-}"             # Remove NN-
  ARTEFACT_NAME="${ARTEFACT_NAME%.conf.bash}"       # Remove .conf.bash
  ARTEFACT_PATH="$RSYNC_ARTEFACTS_DIR/$ARTEFACT_NAME"

  # Reset config variables
  unset CMD_BEFORE_BACKUP CMD_AFTER_BACKUP INCLUDE_PATHS EXCLUDE_PATHS
  declare -a INCLUDE_PATHS EXCLUDE_PATHS

  source "$CONFIG"

  logger -p user.info -t "$LOGGER_TAG" "Starting backup for: $ARTEFACT_NAME"

  if [[ -n "${CMD_BEFORE_BACKUP:-}" ]]; then
    logger -p user.info -t "$LOGGER_TAG" "Running CMD_BEFORE_BACKUP for: $ARTEFACT_NAME"
    eval "$CMD_BEFORE_BACKUP"
  fi

  RSYNC_OPTS=(-a --delete)
  for EXCL in "${EXCLUDE_PATHS[@]:-}"; do
    RSYNC_OPTS+=(--exclude="$EXCL")
  done

  mkdir -p "$ARTEFACT_PATH"

  logger -p user.info -t "$LOGGER_TAG" "Syncing: ${INCLUDE_PATHS[*]} -> $ARTEFACT_PATH"
  rsync "${RSYNC_OPTS[@]}" "${INCLUDE_PATHS[@]}" "$ARTEFACT_PATH"

  if [[ -n "${CMD_AFTER_BACKUP:-}" ]]; then
    logger -p user.info -t "$LOGGER_TAG" "Running CMD_AFTER_BACKUP for: $ARTEFACT_NAME"
    eval "$CMD_AFTER_BACKUP"
  fi

  logger -p user.info -t "$LOGGER_TAG" "Backup completed for: $ARTEFACT_NAME"
done

logger -p user.info -t "$LOGGER_TAG" "RSYNC module execution finished."
