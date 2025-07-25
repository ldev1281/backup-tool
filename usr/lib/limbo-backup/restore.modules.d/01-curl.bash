#!/bin/bash
set -euo pipefail

#########################################################################

# Load global and user configuration
source /usr/lib/limbo-backup/restore.defaults.bash
source /etc/limbo-backup/restore.conf.bash

#########################################################################

#
logger -p user.info -s -t "$LOGGER_TAG" "Starting curl module..."

#########################################################################

#
REMOTE_BACKUP_NAME=$(basename "${BACKUP_PATH%%\?*}")

# Select destination folder using the file extension
if [[ "$REMOTE_BACKUP_NAME" == *.tar.gz.gpg ]]; then
  if [[ "${GPG_ENABLED:-0}" -eq 0 ]]; then
    logger -p user.err -s -t "$LOGGER_TAG" "$REMOTE_BACKUP_NAME is a GPG-encrypted archive but GPG module is disabled in the config."
    exit 1
  else
    TARGET_DIR="$GPG_ARTEFACTS_DIR"
    TARGET_EXT=".tar.gz.gpg"
  fi
elif [[ "$REMOTE_BACKUP_NAME" == *.tar.gz ]]; then
  TARGET_DIR="$TAR_ARTEFACTS_DIR"
  TARGET_EXT=".tar.gz"
else
  logger -p user.err -s -t "$LOGGER_TAG" "Unsupported archive filename extension: $REMOTE_BACKUP_NAME"
  exit 1
fi

#########################################################################

# create folders

mkdir -p "$TARGET_DIR"

# Generate rclone proxy URL
CURL_PROXY="${CURL_PROXY_PROTO:+${CURL_PROXY_PROTO}://}${CURL_PROXY_USER:+${CURL_PROXY_USER}}\
${CURL_PROXY_PASSWORD:+:${CURL_PROXY_PASSWORD}}${CURL_PROXY_USER:+@}${CURL_PROXY_HOST:+${CURL_PROXY_HOST}}${CURL_PROXY_PORT:+:${CURL_PROXY_PORT}}"

#########################################################################

# Download or copy file

TARGET_PATH="$TARGET_DIR/${BACKUP_NAME}${TARGET_EXT}"

if [[ "$BACKUP_PATH" == http://* || "$BACKUP_PATH" == https://* || "$BACKUP_PATH" == file://* ]]; then
  logger -p user.info -s -t "$LOGGER_TAG" "Downloading backup: $BACKUP_PATH → $TARGET_PATH"
  ${CURL_PROXY:+env https_proxy="${CURL_PROXY}" http_proxy="${CURL_PROXY}"} curl -fSL --silent --show-error "$BACKUP_PATH" -o "$TARGET_PATH" || {
    logger -p user.err -s -t "$LOGGER_TAG" "Error during downloading backup: $BACKUP_PATH → $TARGET_PATH"
    exit 1
  }
else
  logger -p user.info -s -t "$LOGGER_TAG" "Copying backup: $BACKUP_PATH → $TARGET_PATH"
  cp "$BACKUP_PATH" "$TARGET_PATH" || {
    logger -p user.err -s -t "$LOGGER_TAG" "Error during copying backup: $BACKUP_PATH → $TARGET_PATH"
    exit 1
  }
fi

#########################################################################

# Verify that input file exists
if [[ ! -f "$TARGET_PATH" ]]; then
  logger -p user.err -s -t "$LOGGER_TAG" "Backup file not found: $TARGET_PATH"
  exit 1
fi

#
logger -p user.info -s -t "$LOGGER_TAG" "curl module finished successfully."
