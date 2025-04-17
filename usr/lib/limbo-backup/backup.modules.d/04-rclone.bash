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

#########################################################################

# Verify that input file exists
if [[ ! -f "$LOCAL_PATH_CURRENT" ]]; then
  logger -p user.err -t "$LOGGER_TAG" "Upload source file not found: $LOCAL_PATH_CURRENT"
  exit 1
fi

# Check required configuration variables
: "${RCLONE_PROTO:?RCLONE_PROTO is not set}"

logger -p user.info -t "$LOGGER_TAG" "Uploading using protocol: $RCLONE_PROTO"

# Generate rclone backend URL based on protocol
case "$RCLONE_PROTO" in

  sftp)
    : "${RCLONE_SFTP_HOST:?RCLONE_SFTP_HOST is not set}"
    : "${RCLONE_SFTP_PORT:?RCLONE_SFTP_PORT is not set}"
    : "${RCLONE_SFTP_USER:?RCLONE_SFTP_USER is not set}"
    : "${RCLONE_SFTP_PASS:?RCLONE_SFTP_PASS is not set}"
    : "${RCLONE_SFTP_REMOTE_PATH:?RCLONE_SFTP_REMOTE_PATH is not set}"

    RCLONE_REMOTE_BASE=":sftp,host=${RCLONE_SFTP_HOST},user=${RCLONE_SFTP_USER},port=${RCLONE_SFTP_PORT}:"
    RCLONE_EXTRA_FLAGS=(--sftp-pass="$(rclone obscure "$RCLONE_SFTP_PASS")")

    REMOTE_PATH="${RCLONE_SFTP_REMOTE_PATH#/}"
    ;;


  s3)
    : "${RCLONE_S3_BUCKET:?RCLONE_S3_BUCKET is not set}"
    : "${RCLONE_S3_KEY:?RCLONE_S3_KEY is not set}"
    : "${RCLONE_S3_SECRET:?RCLONE_S3_SECRET is not set}"
    : "${RCLONE_S3_REMOTE_PATH:?RCLONE_S3_REMOTE_PATH is not set}"

    # Build on-the-fly S3 remote
    RCLONE_REMOTE_BASE=":s3"
    RCLONE_REMOTE_BASE+=",provider=${RCLONE_S3_PROVIDER:-AWS}"
    RCLONE_REMOTE_BASE+=",access_key_id=${RCLONE_S3_KEY}"
    RCLONE_REMOTE_BASE+=",secret_access_key=${RCLONE_S3_SECRET}"
    [[ -n "${RCLONE_S3_ENDPOINT:-}" ]] && RCLONE_REMOTE_BASE+=",endpoint=${RCLONE_S3_ENDPOINT}"
    [[ -n "${RCLONE_S3_REGION:-}" ]] && RCLONE_REMOTE_BASE+=",region=${RCLONE_S3_REGION}"
    RCLONE_REMOTE_BASE+=":${RCLONE_S3_BUCKET}"

    # Additional S3 flags
    RCLONE_EXTRA_FLAGS=()
    [[ -n "${RCLONE_S3_STORAGE_CLASS:-}" ]] && RCLONE_EXTRA_FLAGS+=(--s3-storage-class="$RCLONE_S3_STORAGE_CLASS")
    [[ -n "${RCLONE_S3_ACL:-}" ]] && RCLONE_EXTRA_FLAGS+=(--s3-acl="$RCLONE_S3_ACL")
    [[ -n "${RCLONE_S3_SERVER_SIDE_ENCRYPTION:-}" ]] && RCLONE_EXTRA_FLAGS+=(--s3-server-side-encryption="$RCLONE_S3_SERVER_SIDE_ENCRYPTION")

    REMOTE_PATH="${RCLONE_S3_REMOTE_PATH#/}"
    ;;


  *)
    logger -p user.err -t "$LOGGER_TAG" "Unsupported RCLONE_PROTO: $RCLONE_PROTO"
    exit 1
    ;;
  
esac


#########################################################################

# Upload the "current" backup
REMOTE_PATH_CURRENT="${REMOTE_PATH}/${BACKUP_NAME}${BACKUP_FILENAME_EXTENSION}"

logger -p user.info -t "$LOGGER_TAG" "Uploading backup: $LOCAL_PATH_CURRENT → $REMOTE_PATH_CURRENT"

rclone copyto "$LOCAL_PATH_CURRENT" "${RCLONE_REMOTE_BASE}/${REMOTE_PATH_CURRENT}" \
  "${RCLONE_EXTRA_FLAGS[@]}" \
  --no-traverse

#########################################################################

# Versioned paths based on date
TODAY=$(date +'%Y-%m-%d')
MONTH=$(date +'%Y-%m')
YEAR=$(date +'%Y')

for SUFFIX in "$YEAR" "$MONTH" "$TODAY"; do
  REMOTE_PATH_VERSIONED="$REMOTE_PATH/${BACKUP_NAME}.${SUFFIX}${BACKUP_FILENAME_EXTENSION}"
  logger -p user.info -t "$LOGGER_TAG" "Creating versioned copy: $REMOTE_PATH_VERSIONED"
  rclone copyto "${RCLONE_REMOTE_BASE}/${REMOTE_PATH_CURRENT}" "${RCLONE_REMOTE_BASE}/${REMOTE_PATH_VERSIONED}" \
    "${RCLONE_EXTRA_FLAGS[@]}" \
    --no-traverse
done

#########################################################################

#
logger -p user.info -t "$LOGGER_TAG" "rclone upload module finished successfully."
