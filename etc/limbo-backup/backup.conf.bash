
# === Global settings ===

BACKUP_NAME="limbo-backup"
ARTEFACTS_DIR="/var/lib/limbo-backup/artefacts"

# === Module-specific settings ===

#
RSYNC_ARTEFACTS_DIR="$ARTEFACTS_DIR/backup-rsync"

#
TAR_ARTEFACTS_DIR="$ARTEFACTS_DIR/backup-tar"

#
GPG_ARTEFACTS_DIR="$ARTEFACTS_DIR/backup-gpg"
GPG_DELETE_TAR_SOURCE=1
GPG_FINGERPRINT=""

#
RCLONE_PROTO="sftp"
RCLONE_HOST="my.server.com"
RCLONE_PORT="22"
RCLONE_USER="user"
RCLONE_PASS="mySuperSecretPassword"
RCLONE_REMOTE_PATH="/backups"
