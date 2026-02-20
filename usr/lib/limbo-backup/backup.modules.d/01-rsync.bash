#!/bin/bash
set -euo pipefail

#########################################################################

# Load backup configuration
source /usr/lib/limbo-backup/backup.defaults.bash
source /etc/limbo-backup/backup.conf.bash

#
METADATA_DIR="$RSYNC_ARTEFACTS_DIR/.limbo-backup"

#########################################################################

#
logger -p user.info -t "$LOGGER_TAG" "Starting RSYNC module execution..."

#########################################################################

# create folders
: "${RSYNC_ARTEFACTS_DIR:?RSYNC_ARTEFACTS_DIR is not set or empty}"

rm -rf -- "$RSYNC_ARTEFACTS_DIR"
mkdir -p -- "$RSYNC_ARTEFACTS_DIR"
mkdir -p -- "$METADATA_DIR"

# backup config
rsync -aR --delete "$CONFIG_DIR" "$METADATA_DIR"

# backup version
rsync -aR --delete "$VERSION_FILE" "$METADATA_DIR"

#########################################################################

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

  if declare -p CMD_BEFORE_BACKUP &>/dev/null; then
    logger -p user.info -t "$LOGGER_TAG" "Running CMD_BEFORE_BACKUP for: $ARTEFACT_NAME"
    if [[ "$(declare -p CMD_BEFORE_BACKUP 2>/dev/null)" == declare\ -a* ]]; then
      for __cmd in "${CMD_BEFORE_BACKUP[@]}"; do
        [[ -z "$__cmd" ]] && continue
        logger -p user.info -t "$LOGGER_TAG" "CMD_BEFORE_BACKUP: executing: $__cmd"
        eval "$__cmd"
      done
    else
      if [[ -n "${CMD_BEFORE_BACKUP:-}" ]]; then
        logger -p user.info -t "$LOGGER_TAG" "CMD_BEFORE_BACKUP: executing: $CMD_BEFORE_BACKUP"
        eval "$CMD_BEFORE_BACKUP"
      fi
    fi
  fi

  RSYNC_OPTS=(-aR --delete)
  for EXCL in "${EXCLUDE_PATHS[@]:-}"; do
    RSYNC_OPTS+=(--exclude="$EXCL")
  done

  mkdir -p "$ARTEFACT_PATH"

  logger -p user.info -t "$LOGGER_TAG" "Syncing: ${INCLUDE_PATHS[*]} -> $ARTEFACT_PATH"
  rsync "${RSYNC_OPTS[@]}" "${INCLUDE_PATHS[@]}" "$ARTEFACT_PATH"

  if declare -p CMD_AFTER_BACKUP &>/dev/null; then
    logger -p user.info -t "$LOGGER_TAG" "Running CMD_AFTER_BACKUP for: $ARTEFACT_NAME"
    if [[ "$(declare -p CMD_AFTER_BACKUP 2>/dev/null)" == declare\ -a* ]]; then
      for __cmd in "${CMD_AFTER_BACKUP[@]}"; do
        [[ -z "$__cmd" ]] && continue
        logger -p user.info -t "$LOGGER_TAG" "CMD_AFTER_BACKUP: executing: $__cmd"
        eval "$__cmd"
      done
    else
      if [[ -n "${CMD_AFTER_BACKUP:-}" ]]; then
        logger -p user.info -t "$LOGGER_TAG" "CMD_AFTER_BACKUP: executing: $CMD_AFTER_BACKUP"
        eval "$CMD_AFTER_BACKUP"
      fi
    fi
  fi

  logger -p user.info -t "$LOGGER_TAG" "Backup completed for: $ARTEFACT_NAME"
done

#########################################################################

#
logger -p user.info -t "$LOGGER_TAG" "RSYNC module execution finished."
