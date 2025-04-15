#!/bin/bash
set -euo pipefail

#########################################################################

# Load global config and user config
source /usr/lib/limbo-backup/backup.defaults.bash
source /etc/limbo-backup/backup.conf.bash

# Define input and output paths
TAR_SOURCE_PATH="$TAR_ARTEFACTS_DIR/${BACKUP_NAME}.tar.gz"
GPG_OUTPUT_PATH="$GPG_ARTEFACTS_DIR/${BACKUP_NAME}.tar.gz.gpg"

#########################################################################

# Skip module if no fingerprint
if [[ -z "${GPG_FINGERPRINT:-}" ]]; then
  logger -p user.info -t "$LOGGER_TAG" "GPG_FINGERPRINT not set — skipping encryption module"
  exit 0
fi

#
logger -p user.info -t "$LOGGER_TAG" "Starting GPG encryption module..."

#########################################################################

# Validate GPG key
if ! gpg --list-keys "$GPG_FINGERPRINT" > /dev/null 2>&1; then
  logger -p user.err -t "$LOGGER_TAG" "GPG key with fingerprint '$GPG_FINGERPRINT' not found in keyring"

  logger -p user.info -t "$LOGGER_TAG" "Available GPG keys:"
  gpg --list-keys --with-colons | grep '^fpr' | cut -d: -f10 | while read -r fpr; do
    logger -p user.info -t "$LOGGER_TAG" "  $fpr"
  done

  exit 1
fi

#########################################################################

# Create output dir if needed
mkdir -p "$GPG_ARTEFACTS_DIR"

# Encrypt archive
if [[ ! -f "$TAR_SOURCE_PATH" ]]; then
  logger -p user.err -t "$LOGGER_TAG" "TAR source archive not found: $TAR_SOURCE_PATH"
  exit 1
fi
logger -p user.info -t "$LOGGER_TAG" "Encrypting archive using GPG key: $GPG_FINGERPRINT"
gpg --batch --yes --trust-model always --output "$GPG_OUTPUT_PATH" --recipient "$GPG_FINGERPRINT" --encrypt "$TAR_SOURCE_PATH"
logger -p user.info -t "$LOGGER_TAG" "Encryption complete: $GPG_OUTPUT_PATH"

#########################################################################

# Optionally delete source
if [[ "${GPG_DELETE_TAR_SOURCE:-0}" -eq 1 ]]; then
  logger -p user.info -t "$LOGGER_TAG" "Removing original TAR source: $TAR_SOURCE_PATH"
  rm -f "$TAR_SOURCE_PATH"
fi

#########################################################################

#
logger -p user.info -t "$LOGGER_TAG" "GPG module finished."