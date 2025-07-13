#!/bin/bash
set -euo pipefail

#########################################################################

# Load backup configuration
source /usr/lib/limbo-backup/restore.defaults.bash
source /etc/limbo-backup/restore.conf.bash

#########################################################################

#
logger -p user.info -t "$LOGGER_TAG" "Starting RSYNC module execution..."

#########################################################################

# Find all matching config files and sort by name
mapfile -t RSYNC_CONFIG_FILES < <(find "$RSYNC_CONFIG_DIR" -type f -name '[0-9][0-9]-*.conf.bash' | sort)

declare RESTORE_ARTEFACT=0

for CONFIG in "${RSYNC_CONFIG_FILES[@]}"; do
  CONFIG_FILENAME="$(basename "$CONFIG")"
  ARTEFACT_NAME="${CONFIG_FILENAME#*-}"             # Remove NN-
  ARTEFACT_NAME="${ARTEFACT_NAME%.conf.bash}"       # Remove .conf.bash
  ARTEFACT_PATH="$RSYNC_ARTEFACTS_DIR/$ARTEFACT_NAME"

  if [[ ${#RESTORE_APPS[@]} -gt 0 ]]; then
    RESTORE_ARTEFACT=0
    for app in "${RESTORE_APPS[@]}"; do
      if [[ "$app" == "$ARTEFACT_NAME" ]]; then
        RESTORE_ARTEFACT=1
        break
      fi
    done

    if [[ "$RESTORE_ARTEFACT" -eq 0 ]]; then
      logger -p user.info -t "$LOGGER_TAG" "Skipping restore for: $ARTEFACT_NAME"    
      continue
    fi
  else
    logger -p user.err -t "$LOGGER_TAG" "RESTORE_APPS is not set in restore.conf.bash"
  fi

  # Reset config variables
  unset CMD_BEFORE_RESTORE CMD_AFTER_RESTORE INCLUDE_PATHS EXCLUDE_PATHS
  declare -a INCLUDE_PATHS EXCLUDE_PATHS

  source "$CONFIG"

  logger -p user.info -t "$LOGGER_TAG" "Starting restore for: $ARTEFACT_NAME"

  if [[ -n "${CMD_BEFORE_RESTORE:-}" ]]; then
    logger -p user.info -t "$LOGGER_TAG" "Running CMD_BEFORE_RESTORE for: $ARTEFACT_NAME"
    eval "$CMD_BEFORE_RESTORE"
  fi

  RSYNC_OPTS=(-aR)
 
  for INCLUDE_PATH in "${INCLUDE_PATHS[@]}"; do
    RELATIVE_PATH="${INCLUDE_PATH#/}"
    SRC_PATH="$ARTEFACT_PATH/$RELATIVE_PATH"
    DST_PATH="$INCLUDE_PATH"

    if [[ -z "$RESTORE_OVERWRITE" ]]; then
      RSYNC_OPTS+=("--backup" "--suffix=$(date +%Y%m%d_%H%M%S).bak")
    fi

    logger -p user.info -t "$LOGGER_TAG" "Syncing: $SRC_PATH -> $DST_PATH"
    rsync "${RSYNC_OPTS[@]}" "$SRC_PATH" "$DST_PATH"  
  done


  if [[ -n "${CMD_AFTER_RESTORE:-}" ]]; then
    logger -p user.info -t "$LOGGER_TAG" "Running CMD_AFTER_RESTORE for: $ARTEFACT_NAME"
    eval "$CMD_AFTER_RESTORE"
  fi

  logger -p user.info -t "$LOGGER_TAG" "Restore completed for: $ARTEFACT_NAME"
done

#########################################################################

#
logger -p user.info -t "$LOGGER_TAG" "RSYNC module execution finished."
