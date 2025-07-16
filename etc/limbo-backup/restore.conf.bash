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

# If set to 1, the original .tar.gz file will be deleted after extracting.
# If 0, it will be kept.
TAR_DELETE_TAR_SOURCE=1

# Directory where rsync module backups the local files and dirs if they are missed in the backup archive and RESTORE_OVERWRITE is empty.
VERSIONS_ARTEFACTS_DIR="$ARTEFACTS_DIR/restore-versions/$(date +%Y%m%d_%H%M%S)/"

# === gpg module settings ===

# Enables or disables the gpg module.
# 1 = enabled, 0 = disabled
GPG_ENABLED=0

# Directory where GPG-encrypted archives are stored (.tar.gz.gpg).
GPG_ARTEFACTS_DIR="$ARTEFACTS_DIR/restore-gpg"

# If set to 1, the original .tar.gz.gpg file will be deleted after decryption.
# If 0, it will be kept.
GPG_DELETE_GPG_SOURCE=1