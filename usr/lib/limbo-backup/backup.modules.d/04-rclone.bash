#!/bin/bash
set -euo pipefail

#########################################################################

# Load global and user configuration
source /usr/lib/limbo-backup/backup.defaults.bash
source /etc/limbo-backup/backup.conf.bash

#########################################################################

# Skip if disabled
if [[ "${RCLONE_ENABLED:-0}" -ne 1 ]]; then
  logger -p user.info -t "$LOGGER_TAG" "rclone module is disabled — skipping"
  exit 0
fi

#
logger -p user.info -t "$LOGGER_TAG" "Starting rclone module..."

#########################################################################

# Determine input file based on GPG usage
if [[ "${GPG_ENABLED:-0}" -eq 1 ]]; then
  BACKUP_FILENAME_EXTENSION=".tar.gz.gpg"
  LOCAL_PATH_CURRENT="$GPG_ARTEFACTS_DIR/${BACKUP_NAME}${BACKUP_FILENAME_EXTENSION}"
else
  BACKUP_FILENAME_EXTENSION=".tar.gz"
  LOCAL_PATH_CURRENT="$TAR_ARTEFACTS_DIR/${BACKUP_NAME}${BACKUP_FILENAME_EXTENSION}"
fi
REMOTE_PATH_CURRENT="$RCLONE_REMOTE_PATH/${BACKUP_NAME}${BACKUP_FILENAME_EXTENSION}"

#########################################################################

# Verify that input file exists
if [[ ! -f "$LOCAL_PATH_CURRENT" ]]; then
  logger -p user.err -t "$LOGGER_TAG" "Upload source file not found: $LOCAL_PATH_CURRENT"
  exit 1
fi

# Check required configuration variables
: "${RCLONE_PROTO:?RCLONE_PROTO is not set}"

logger -p user.info -t "$LOGGER_TAG" "Uploading using protocol: $RCLONE_PROTO"

# Obscure password for rclone
RCLONE_PASS_OBFUSCURED=$(rclone obscure "$RCLONE_PASS")

# Generate rclone backend URL based on protocol
case "$RCLONE_PROTO" in
  sftp)
    : "${RCLONE_HOST:?RCLONE_HOST is not set}"
    : "${RCLONE_PORT:?RCLONE_PORT is not set}"
    : "${RCLONE_USER:?RCLONE_USER is not set}"
    : "${RCLONE_PASS:?RCLONE_PASS is not set}"

    RCLONE_REMOTE_BASE=":sftp,host=${RCLONE_HOST},user=${RCLONE_USER},port=${RCLONE_PORT}"
    RCLONE_EXTRA_FLAGS=(--sftp-pass="$(rclone obscure "$RCLONE_PASS")")
    ;;
  s3)
    : "${RCLONE_S3_BUCKET:?RCLONE_S3_BUCKET is not set}"
    : "${RCLONE_S3_KEY:?RCLONE_S3_KEY is not set}"
    : "${RCLONE_S3_SECRET:?RCLONE_S3_SECRET is not set}"
    : "${RCLONE_S3_REGION:?RCLONE_S3_REGION is not set}"

    RCLONE_REMOTE_BASE=":s3:${RCLONE_S3_BUCKET}"
    RCLONE_EXTRA_FLAGS=(
      --s3-access-key-id="$RCLONE_S3_KEY"
      --s3-secret-access-key="$RCLONE_S3_SECRET"
      --s3-region="$RCLONE_S3_REGION"
    )

    if [[ -n "${RCLONE_S3_ENDPOINT:-}" ]]; then
        RCLONE_EXTRA_FLAGS+=(--s3-endpoint="$RCLONE_S3_ENDPOINT")
    fi

    if [[ -n "${RCLONE_S3_STORAGE_CLASS:-}" ]]; then
        RCLONE_EXTRA_FLAGS+=(--s3-storage-class="$RCLONE_S3_STORAGE_CLASS")
    fi

    if [[ -n "${RCLONE_S3_ACL:-}" ]]; then
        RCLONE_EXTRA_FLAGS+=(--s3-acl="$RCLONE_S3_ACL")
    fi

    if [[ -n "${RCLONE_S3_SERVER_SIDE_ENCRYPTION:-}" ]]; then
        RCLONE_EXTRA_FLAGS+=(--s3-server-side-encryption="$RCLONE_S3_SERVER_SIDE_ENCRYPTION")
    fi  
    ;;
  *)
    logger -p user.err -t "$LOGGER_TAG" "Unsupported RCLONE_PROTO: $RCLONE_PROTO"
    exit 1
    ;;
esac

# Upload the "current" backup
logger -p user.info -t "$LOGGER_TAG" "Uploading backup: $LOCAL_PATH_CURRENT → $REMOTE_PATH_CURRENT"
rclone copyto "$LOCAL_PATH_CURRENT" "$RCLONE_REMOTE_BASE:$REMOTE_PATH_CURRENT" \
  "${RCLONE_EXTRA_FLAGS[@]}" \
  --no-traverse

# Versioned paths based on date
TODAY=$(date +'%Y-%m-%d')
MONTH=$(date +'%Y-%m')
YEAR=$(date +'%Y')

for SUFFIX in "$YEAR" "$MONTH" "$TODAY"; do
  REMOTE_PATH_VERSIONED="$RCLONE_REMOTE_PATH/${BACKUP_NAME}.${SUFFIX}${BACKUP_FILENAME_EXTENSION}"
  logger -p user.info -t "$LOGGER_TAG" "Creating versioned copy: $REMOTE_PATH_VERSIONED"
  rclone copyto "$RCLONE_REMOTE_BASE:$REMOTE_PATH_CURRENT" "$RCLONE_REMOTE_BASE:$REMOTE_PATH_VERSIONED" \
    "${RCLONE_EXTRA_FLAGS[@]}" \
    --no-traverse
done

#########################################################################

#
logger -p user.info -t "$LOGGER_TAG" "rclone upload module finished successfully."
