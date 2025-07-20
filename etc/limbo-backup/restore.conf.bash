# === Global settings ===

# The name of the backup, used as the base filename for all artefacts (tar, gpg, remote).
BACKUP_NAME="limbo-backup"

# By default restore all applications from the backup archive. You can specify only particular ones, e.g ("keycloak" "wekan")
# You can also override this value by using --apps option for the restore script
RESTORE_APPS=("*")

# By default, all files to be overwritten or deleted are first backed up to the `RESTORE_ARCHIVES_DIR` directory
# 1 = enabled, 0 = disabled
RESTORE_KEEP_LOCAL=1

# The root directory for all backup artefacts (rsync, tar, gpg).
ARTEFACTS_DIR="/var/lib/limbo-backup/artefacts"

# Directory where rsync module backups the local files and dirs when they are being replaced or deleted (when they are missed in the backup archive) and RESTORE_KEEP_LOCAL is enabled
RESTORE_ARCHIVES_DIR="$ARTEFACTS_DIR/restore-archives/$(date +%Y%m%d_%H%M%S)/"

# === Module-specific settings ===

# Directory where rsync module takes the raw backup files to restore.
RSYNC_ARTEFACTS_DIR="$ARTEFACTS_DIR/restore-rsync"

# Directory where tar module stores uncompressed backup archives (.tar). 
TAR_ARTEFACTS_DIR="$ARTEFACTS_DIR/restore-tar"

# If set to 1, the original .tar.gz file will be deleted after extracting.
# If 0, it will be kept.
TAR_DELETE_TAR_SOURCE=1

# === gpg module settings ===

# Enables or disables the gpg module.
# 1 = enabled, 0 = disabled
GPG_ENABLED=0

# Directory where GPG-encrypted archives are stored (.tar.gz.gpg).
GPG_ARTEFACTS_DIR="$ARTEFACTS_DIR/restore-gpg"

# If set to 1, the original .tar.gz.gpg file will be deleted after decryption.
# If 0, it will be kept.
GPG_DELETE_GPG_SOURCE=1
