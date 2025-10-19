#!/bin/bash

# === Local Couchbase Backup Script ===
# Usage: ./backup.sh

# === Script Parameters ===
# Docker command parameters
DOCKER_PS_FORMAT="{{.Names}}"                 # Output format for docker ps
DOCKER_FILTER_PATTERNS=("^$" "failed" "console" "handle")  # Filter out invalid lines

# Backup parameters
DEFAULT_BACKUP_DIR="./backups"                # Default backup directory
BACKUP_REPO_DIR="repo"                        # Repository folder name
MAX_BACKUP_COUNT=3                            # Max number of backups to keep

# Couchbase parameters
CB_ARCHIVE_PATH="/backups/repo"               # Backup path inside container
CB_REPO_NAME="default"                        # Couchbase repository name
CB_CLUSTER_URL="couchbase://localhost"        # Couchbase cluster URL
CB_USERNAME="Administrator"                   # Couchbase username
CB_PASSWORD="Administrator"                   # Couchbase password

echo "🔗 Checking local Docker containers..."
echo

# === List running containers ===
echo "📦 Running Docker Containers:"
containers=($(docker ps --format "${DOCKER_PS_FORMAT}" 2>/dev/null | grep -v "${DOCKER_FILTER_PATTERNS[0]}" | grep -v "${DOCKER_FILTER_PATTERNS[1]}" | grep -v "${DOCKER_FILTER_PATTERNS[2]}" | grep -v "${DOCKER_FILTER_PATTERNS[3]}"))

if [ ${#containers[@]} -eq 0 ]; then
    echo "❌ No running containers found!"
    exit 1
fi

# Display containers with numbering
for i in "${!containers[@]}"; do
    echo "[$((i+1))] ${containers[i]}"
done

echo
read -p "💬 Select the container number you want to back up (1-${#containers[@]}): " choice

# Validate selection
if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#containers[@]} ]; then
    echo "❌ Invalid selection!"
    exit 1
fi

CONTAINER_NAME=${containers[$((choice-1))]}
echo "✅ Selected container: $CONTAINER_NAME"
echo

# Ask for backup directory
read -p "💬 Enter backup directory path (example: ./backups): " BACKUP_DIR

if [ -z "$BACKUP_DIR" ]; then
    BACKUP_DIR="${DEFAULT_BACKUP_DIR}"
fi

# Create backup directory
mkdir -p "${BACKUP_DIR}/${BACKUP_REPO_DIR}"
echo "📁 Backup directory created: ${BACKUP_DIR}/${BACKUP_REPO_DIR}"

# If Couchbase container → special backup logic
if [[ "$CONTAINER_NAME" == *"couchbase"* ]]; then
    echo
    echo "⚙️  Preparing Couchbase backup repository..."

    # Fix Windows path issue for Git Bash
    if [[ "$BACKUP_DIR" == /* ]]; then
        BACKUP_DIR="./backups"
        echo "⚠️  Absolute paths are not supported on Windows; using ./backups instead"
    fi

    # Ensure local backup directory exists
    mkdir -p "${BACKUP_DIR}/${BACKUP_REPO_DIR}"

    # Convert to Windows path format (for Docker Desktop)
    WINDOWS_BACKUP_DIR=$(cygpath -w "$(realpath "${BACKUP_DIR}")" 2>/dev/null || echo "$(pwd)/${BACKUP_DIR}")

    # Create repo inside the container and run backup
    echo "⚙️  Initializing Couchbase backup repository..."
    docker exec ${CONTAINER_NAME} cbbackupmgr config --archive ${CB_ARCHIVE_PATH} --repo ${CB_REPO_NAME}

    echo "🚀 Starting Couchbase backup..."
    docker exec ${CONTAINER_NAME} cbbackupmgr backup \
      --archive ${CB_ARCHIVE_PATH} \
      --repo ${CB_REPO_NAME} \
      --cluster ${CB_CLUSTER_URL} \
      --username ${CB_USERNAME} \
      --password ${CB_PASSWORD} || {
        echo "❌ Backup failed!"
        exit 1
      }

    # Copy backup files to host
    echo "📁 Copying backup files to local machine..."
    docker cp ${CONTAINER_NAME}:${CB_ARCHIVE_PATH} "${BACKUP_DIR}/" || {
        echo "⚠️  Could not copy backup files; they remain inside the container."
        exit 1
    }

    # Compress the backup
    echo "🗜️  Compressing backup files..."
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    COMPRESSED_BACKUP="${BACKUP_DIR}/couchbase-backup-${TIMESTAMP}.tar.gz"
    tar -czf "${COMPRESSED_BACKUP}" -C "${BACKUP_DIR}" ${BACKUP_REPO_DIR}

    if [ $? -eq 0 ]; then
        echo "✅ Backup compressed: ${COMPRESSED_BACKUP}"
        # Remove uncompressed repo folder
        rm -rf "${BACKUP_DIR}/${BACKUP_REPO_DIR}"
        echo "🧹 Temporary files cleaned up"
    else
        echo "❌ Compression failed!"
        exit 1
    fi

    # Remove old backups (keep last MAX_BACKUP_COUNT)
    echo "🧹 Cleaning up old backups..."
    cd "${BACKUP_DIR}"
    ls -t couchbase-backup-*.tar.gz 2>/dev/null | tail -n +$((MAX_BACKUP_COUNT+1)) | xargs -r rm -f
    REMAINING_BACKUPS=$(ls -1 couchbase-backup-*.tar.gz 2>/dev/null | wc -l)
    echo "📊 Remaining backups: ${REMAINING_BACKUPS}"

else
    # General backup for non-Couchbase containers
    echo
    echo "🚀 Creating container backup..."
    BACKUP_FILE="${BACKUP_DIR}/${CONTAINER_NAME}-backup-$(date +%Y%m%d-%H%M%S).tar"
    docker export ${CONTAINER_NAME} > "${BACKUP_FILE}"

    if [ $? -eq 0 ]; then
        echo "✅ Container backup completed: ${BACKUP_FILE}"
    else
        echo "❌ Backup failed!"
        exit 1
    fi
fi

echo
echo "✅ Backup completed successfully."
echo "📂 Backup location: ${BACKUP_DIR}"
