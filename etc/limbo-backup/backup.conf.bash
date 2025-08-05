# === Global settings ===

# The name of the backup, used as the base filename for all artefacts (tar, gpg, remote).
BACKUP_NAME="limbo-backup"

# The root directory for all backup artefacts (rsync, tar, gpg).
ARTEFACTS_DIR="/var/lib/limbo-backup/artefacts"

# === Module-specific settings ===

# Directory where rsync module stores the raw backup files.
RSYNC_ARTEFACTS_DIR="$ARTEFACTS_DIR/backup-rsync"

# Directory where tar module stores compressed backup archives (.tar.gz).
TAR_ARTEFACTS_DIR="$ARTEFACTS_DIR/backup-tar"

# === gpg module settings ===

# Enables or disables the gpg module.
# 1 = enabled, 0 = disabled
GPG_ENABLED=0

# Directory where GPG-encrypted archives are stored (.tar.gz.gpg).
GPG_ARTEFACTS_DIR="$ARTEFACTS_DIR/backup-gpg"

# If set to 1, the original .tar.gz file will be deleted after encryption.
# If 0, it will be kept.
GPG_DELETE_TAR_SOURCE=1

# GPG key fingerprint used to encrypt backups.
GPG_FINGERPRINT=""

# === rclone module settings ===

# Enables or disables the rclone upload module.
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
#RCLONE_S3_STORAGE_CLASS="STANDARD"
#RCLONE_S3_ACL="private"
#RCLONE_S3_SERVER_SIDE_ENCRYPTION="AES256"

# Proxy to use with rclone for uploading backups
RCLONE_PROXY="socks5://127.0.0.1:9050"
