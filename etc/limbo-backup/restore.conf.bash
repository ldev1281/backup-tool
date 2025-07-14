# === Global settings ===

# The name of the backup, used as the base filename for all artefacts (tar, gpg, remote).
BACKUP_NAME="limbo-backup"

# By default restore all applications from the backup archive. You can specify only particular ones, e.g ("keycloak" "wekan")
RESTORE_APPS=("*")

# By default do not overwrite existing directories.
RESTORE_OVERWRITE=""

# The root directory for all backup artefacts (rsync, tar, gpg).
ARTEFACTS_DIR="/var/lib/limbo-backup/artefacts"

# === Module-specific settings ===

# Directory where rsync module takes the raw backup files to restore.
RSYNC_ARTEFACTS_DIR="$ARTEFACTS_DIR/restore-rsync"

# Directory where tar module stores uncompressed backup archives (.tar). 
TAR_ARTEFACTS_DIR="$ARTEFACTS_DIR/restore-tar"
# WARNING! If rclone is disabled below (RCLONE_ENABLED=0) you should set this to backup-tar otherwise it won't find an archive to restore: 
# TAR_ARTEFACTS_DIR="$ARTEFACTS_DIR/backup-tar"

# Directory where rsync module backups the local files and dirs if they are missed in the backup archive and RESTORE_OVERWRITE is empty.
VERSIONS_ARTEFACTS_DIR="$ARTEFACTS_DIR/restore-versions"

# === gpg module settings ===

# Enables or disables the gpg module.
# 1 = enabled, 0 = disabled
GPG_ENABLED=0

# Directory where GPG-encrypted archives are stored (.tar.gz.gpg).
GPG_ARTEFACTS_DIR="$ARTEFACTS_DIR/restore-gpg"

# If set to 1, the original .tar.gz.gpg file will be deleted after decryption.
# If 0, it will be kept.
GPG_DELETE_GPG_SOURCE=1

# === rclone module settings ===

# Enables or disables the rclone download module.
# 1 = enabled, 0 = disabled
RCLONE_ENABLED=0

# sftp-protocol settings
#RCLONE_PROTO="sftp"
#RCLONE_SFTP_REMOTE_PATH="backups"
#RCLONE_SFTP_HOST="your.remote.host"
#RCLONE_SFTP_PORT="22"
#RCLONE_SFTP_USER="backupuser"
#RCLONE_SFTP_PASS="secret_password"

# s3-protocol settings
#RCLONE_PROTO="s3"
#RCLONE_S3_REMOTE_PATH="backups"
#RCLONE_S3_ENDPOINT="s3.example.com"
#RCLONE_S3_BUCKET=""
#RCLONE_S3_KEY=""
#RCLONE_S3_SECRET=""
#RCLONE_S3_REGION=""
#RCLONE_S3_PROVIDER="Other"
