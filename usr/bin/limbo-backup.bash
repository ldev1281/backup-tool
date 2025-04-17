#!/bin/bash
set -euo pipefail

source /usr/lib/limbo-backup/backup.defaults.bash
source /etc/limbo-backup/backup.conf.bash

# Directory containing all backup modules
MODULES_DIR="/lib/limbo-backup/backup.modules.d"

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
