#!/bin/bash
set -euo pipefail


# Load global and user configuration
source /usr/lib/limbo-backup/backup.defaults.bash
source /etc/limbo-backup/backup.conf.bash

# Determine input file based on GPG usage
if [[ -n "${GPG_FINGERPRINT:-}" ]]; then
  LOCAL_PATH_CURRENT="$GPG_ARTEFACTS_DIR/${BACKUP_NAME}.tar.gz.gpg"
  REMOTE_PATH_CURRENT="$RCLONE_REMOTE_PATH/${BACKUP_NAME}.tar.gz.gpg"
else
  LOCAL_PATH_CURRENT="$TAR_ARTEFACTS_DIR/${BACKUP_NAME}.tar.gz"
  REMOTE_PATH_CURRENT="$RCLONE_REMOTE_PATH/${BACKUP_NAME}.tar.gz"
fi


#
logger -p user.info -t "$LOGGER_TAG" "Starting rclone encryption module..."


# Verify that input file exists
if [[ ! -f "$LOCAL_PATH_CURRENT" ]]; then
  logger -p user.err -t "$LOGGER_TAG" "Upload source file not found: $LOCAL_PATH_CURRENT"
  exit 1
fi

# Check required configuration variables
: "${RCLONE_PROTO:?RCLONE_PROTO is not set}"
: "${RCLONE_HOST:?RCLONE_HOST is not set}"
: "${RCLONE_PORT:?RCLONE_PORT is not set}"
: "${RCLONE_USER:?RCLONE_USER is not set}"
: "${RCLONE_PASS:?RCLONE_PASS is not set}"
: "${RCLONE_REMOTE_PATH:?RCLONE_REMOTE_PATH is not set}"

logger -p user.info -t "$LOGGER_TAG" "Starting rclone upload module using protocol: $RCLONE_PROTO"

# Obscure password for rclone
RCLONE_PASS_OBFUSCURED=$(rclone obscure "$RCLONE_PASS")

# Generate rclone backend URL based on protocol
case "$RCLONE_PROTO" in
  sftp)
    RCLONE_REMOTE_BASE=":sftp,host=${RCLONE_HOST},user=${RCLONE_USER},port=${RCLONE_PORT}"
    ;;
  *)
    logger -p user.err -t "$LOGGER_TAG" "Unsupported RCLONE_PROTO: $RCLONE_PROTO"
    exit 1
    ;;
esac

# Upload the "current" backup
logger -p user.info -t "$LOGGER_TAG" "Uploading backup: $LOCAL_PATH_CURRENT → $REMOTE_PATH_CURRENT"
rclone copyto "$LOCAL_PATH_CURRENT" "$RCLONE_REMOTE_BASE:$REMOTE_PATH_CURRENT" \
  --sftp-pass="$RCLONE_PASS_OBFUSCURED" \
  --no-traverse

# Versioned paths based on date
TODAY=$(date +'%Y-%m-%d')
MONTH=$(date +'%Y-%m')
YEAR=$(date +'%Y')

REMOTE_PATH_DAY="$RCLONE_REMOTE_PATH/${BACKUP_NAME}.${TODAY}.tar.gz.gpg"
REMOTE_PATH_MONTH="$RCLONE_REMOTE_PATH/${BACKUP_NAME}.${MONTH}.tar.gz.gpg"
REMOTE_PATH_YEAR="$RCLONE_REMOTE_PATH/${BACKUP_NAME}.${YEAR}.tar.gz.gpg"

# Duplicate the "current" for versioned names
#for versioned_path in "$REMOTE_PATH_DAY" "$REMOTE_PATH_MONTH" "$REMOTE_PATH_YEAR"; do
#  logger -p user.info -t "$LOGGER_TAG" "Creating versioned copy: $versioned_path"
#  rclone copy "$RCLONE_REMOTE_TARGET:/$REMOTE_PATH_CURRENT" "$RCLONE_REMOTE_TARGET:/$versioned_path"
#done


#
logger -p user.info -t "$LOGGER_TAG" "rclone upload module finished successfully."
