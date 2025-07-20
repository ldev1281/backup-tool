#!/bin/bash
set -euo pipefail

#########################################################################

# Load backup configuration
source /usr/lib/limbo-backup/restore.defaults.bash
source /etc/limbo-backup/restore.conf.bash

#
METADATA_DIR=".limbo-backup"
METADATA_INCLUDE_PATHS=("$CONFIG_DIR")
#########################################################################

#
logger -p user.info -s -t "$LOGGER_TAG" "Starting RSYNC module execution..."

#########################################################################

# create folders
mkdir -p "$RESTORE_ARCHIVES_DIR"

#########################################################################

# Default rsync options for restoring
RSYNC_OPTS=(-aR --delete)

# Override RESTORE_KEEP_LOCAL with the CLI, if provided
[[ -z "${CLI_RESTORE_KEEP_LOCAL:-}" ]] || RESTORE_KEEP_LOCAL=$CLI_RESTORE_KEEP_LOCAL

# Preserve all files to be overwritten or deleted
if [[ "${RESTORE_KEEP_LOCAL:-1}" -eq 1 ]]; then
  RSYNC_OPTS+=("--backup" "--backup-dir=$RESTORE_ARCHIVES_DIR")
else
  logger -p user.warn -s -t "$LOGGER_TAG" "Restore will not preserve all files and directories to be overwritten or deleted"
fi

####################

# Restore all metadata files from METADATA_INCLUDE_PATHS
ARTEFACT_PATH="$RSYNC_ARTEFACTS_DIR/$METADATA_DIR"

logger -p user.info -s -t "$LOGGER_TAG" "Starting restore for metadata $METADATA_DIR (${METADATA_INCLUDE_PATHS[@]})"

pushd "$ARTEFACT_PATH" >/dev/null

for INCLUDE_PATH in "${METADATA_INCLUDE_PATHS[@]}"; do
  RELATIVE_PATH="${INCLUDE_PATH#/}"

  if [[ ! -e "$RELATIVE_PATH" ]]; then
    logger -p user.warn -s -t "$LOGGER_TAG" "Skip missing: $ARTEFACT_PATH/$RELATIVE_PATH"
    continue
  fi

  logger -p user.info -s -t "$LOGGER_TAG" "Syncing: $RELATIVE_PATH -> /"
  rsync "${RSYNC_OPTS[@]}" "$RELATIVE_PATH" /
done

popd >/dev/null

logger -p user.info -s -t "$LOGGER_TAG" "Restore completed for metadata $METADATA_DIR (${METADATA_INCLUDE_PATHS[@]})"

#########################################################################

# Find all matching config files and sort by name
mapfile -t RSYNC_CONFIG_FILES < <(find "$RSYNC_CONFIG_DIR" -type f -name '[0-9][0-9]-*.conf.bash' | sort)

# Override RESTORE_APPS with the CLI list, if provided
[ -z "${CLI_RESTORE_APPS:-}" ] || IFS=',' read -ra RESTORE_APPS <<<"$CLI_RESTORE_APPS"

# Restore all artefacts or particular ones
if [[ ${#RESTORE_APPS[@]} -eq 0 ]]; then
  logger -p user.err -s -t "$LOGGER_TAG" "RESTORE_APPS was neither set in the config nor provided via CLI option."
  exit 1
fi

declare RESTORE_ARTEFACT=0

for CONFIG in "${RSYNC_CONFIG_FILES[@]}"; do
  CONFIG_FILENAME="$(basename "$CONFIG")"
  ARTEFACT_NAME="${CONFIG_FILENAME#*-}"       # Remove NN-
  ARTEFACT_NAME="${ARTEFACT_NAME%.conf.bash}" # Remove .conf.bash
  ARTEFACT_PATH="$RSYNC_ARTEFACTS_DIR/$ARTEFACT_NAME"

  if [[ "${RESTORE_APPS[0]}" != "*" ]]; then
    RESTORE_ARTEFACT=0
    for RESTORE_APP in "${RESTORE_APPS[@]}"; do
      if [[ "$RESTORE_APP" == "$ARTEFACT_NAME" ]]; then
        RESTORE_ARTEFACT=1
        break
      fi
    done

    if [[ "$RESTORE_ARTEFACT" -eq 0 ]]; then
      logger -p user.warn -s -t "$LOGGER_TAG" "Skipping restore for: $ARTEFACT_NAME"
      continue
    fi
  fi

  # Reset config variables
  unset CMD_BEFORE_RESTORE CMD_AFTER_RESTORE INCLUDE_PATHS EXCLUDE_PATHS
  declare -a INCLUDE_PATHS EXCLUDE_PATHS

  source "$CONFIG"

  logger -p user.info -s -t "$LOGGER_TAG" "Starting restore for: $ARTEFACT_NAME"

  if [[ -n "${CMD_BEFORE_RESTORE:-}" ]]; then
    logger -p user.info -s -t "$LOGGER_TAG" "Running CMD_BEFORE_RESTORE for: $ARTEFACT_NAME"
    eval "$CMD_BEFORE_RESTORE"
  fi

  pushd "$ARTEFACT_PATH" >/dev/null

  for INCLUDE_PATH in "${INCLUDE_PATHS[@]}"; do
    RELATIVE_PATH="${INCLUDE_PATH#/}"

    if [[ ! -e "$RELATIVE_PATH" ]]; then
      logger -p user.warn -s -t "$LOGGER_TAG" "Skip missing: $ARTEFACT_PATH/$RELATIVE_PATH"
      continue
    fi

    logger -p user.info -s -t "$LOGGER_TAG" "Syncing: $RELATIVE_PATH -> /"
    rsync "${RSYNC_OPTS[@]}" "$RELATIVE_PATH" /
  done

  popd >/dev/null

  if [[ -n "${CMD_AFTER_RESTORE:-}" ]]; then
    logger -p user.info -s -t "$LOGGER_TAG" "Running CMD_AFTER_RESTORE for: $ARTEFACT_NAME"
    eval "$CMD_AFTER_RESTORE"
  fi

  logger -p user.info -s -t "$LOGGER_TAG" "Restore completed for: $ARTEFACT_NAME"
done

#########################################################################

#
logger -p user.info -s -t "$LOGGER_TAG" "RSYNC module execution finished."
