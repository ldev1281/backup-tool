#
# Example backup
#


# === Optional commands to execute before and after rsync backup ===

# Command to run before the rsync backup starts.
# This can be used to stop services, lock databases, or prepare the system.
# Leave it commented or empty if no action is needed.
#CMD_BEFORE_BACKUP="docker compose --project-directory /docker/application stop"

# Command to run after the rsync backup completes.
# This is typically used to restart services or clean up temporary states.
#CMD_AFTER_BACKUP="docker compose --project-directory /docker/application start"


# === Paths to include in the backup ===

# List of absolute paths to directories or files that should be backed up via rsync.
# These are the source paths from which data will be copied into the backup artefact.
#INCLUDE_PATHS=(
#  "/docker/application/"
#)


# === Paths to exclude from the backup ===

# List of paths to exclude from the rsync backup.
# These must be subpaths of the INCLUDE_PATHS above.
# Useful for omitting log directories, caches, or runtime-generated files.
#EXCLUDE_PATHS=(
#  "/docker/application/vol/logs/"
#)
