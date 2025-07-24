#!/bin/bash
set -euo pipefail

#########################################################################

# Load global config and user config
source /usr/lib/limbo-backup/restore.defaults.bash
source /etc/limbo-backup/restore.conf.bash

# Define input and output paths
GPG_SOURCE_PATH="$GPG_ARTEFACTS_DIR/${BACKUP_NAME}.tar.gz.gpg"
TAR_OUTPUT_PATH="$TAR_ARTEFACTS_DIR/${BACKUP_NAME}.tar.gz"

#########################################################################

# Skip module if disabled
if [[ "${GPG_ENABLED:-0}" -ne 1 ]]; then
  logger -p user.info -s -t "$LOGGER_TAG" "GPG module is disabled — skipping"
  exit 0
fi

#
logger -p user.info -s -t "$LOGGER_TAG" "Starting GPG decryption module..."

#########################################################################

# create folders
mkdir -p "$TAR_ARTEFACTS_DIR"

#########################################################################

# Decrypt archive
if [[ ! -f "$GPG_SOURCE_PATH" ]]; then
  logger -p user.err -s -t "$LOGGER_TAG" "GPG source archive not found: $GPG_SOURCE_PATH"
  exit 1
fi
logger -p user.info -s -t "$LOGGER_TAG" "Decrypting archive using GPG key"
gpg --batch --yes --trust-model always --output "$TAR_OUTPUT_PATH" --decrypt "$GPG_SOURCE_PATH"
logger -p user.info -s -t "$LOGGER_TAG" "Decryption complete: $TAR_OUTPUT_PATH"

#########################################################################

# Optionally delete source
if [[ "${GPG_DELETE_GPG_SOURCE:-0}" -eq 1 ]]; then
  logger -p user.info -s -t "$LOGGER_TAG" "Removing original GPG source: $GPG_SOURCE_PATH"
  rm -f "$GPG_SOURCE_PATH"
fi

#########################################################################

#
logger -p user.info -s -t "$LOGGER_TAG" "GPG module finished."