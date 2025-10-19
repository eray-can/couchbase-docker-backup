#!/bin/bash

# === Couchbase Restore Script (Windows + Git Bash compatible) ===
# Usage: ./restore.sh
# Note: Your backup file must be in .tar.gz format (example: ./backups/couchbase-backup-20251019-132334.tar.gz)

set -e

# Default parameters
DEFAULT_BACKUP_DIR="./backups"
CB_REPO_NAME="default"
CB_CLUSTER_URL="couchbase://localhost"
CB_USERNAME="Administrator"
CB_PASSWORD="Administrator"

echo "🔗 Checking local Docker containers..."
echo

# === List running containers ===
containers=($(docker ps --format "{{.Names}}" 2>/dev/null | grep -v -E "failed|console|mode|handle|invalid" | grep -v '^$'))
if [ ${#containers[@]} -eq 0 ]; then
    echo "❌ No running containers found!"
    exit 1
fi

echo "📦 Running Docker Containers:"
for i in "${!containers[@]}"; do
    echo "[$((i+1))] ${containers[i]}"
done

echo
read -p "💬 Select the container number for restore (1-${#containers[@]}): " choice
if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#containers[@]} ]; then
    echo "❌ Invalid selection!"
    exit 1
fi

CONTAINER_NAME=${containers[$((choice-1))]}
echo "✅ Selected container: ${CONTAINER_NAME}"
echo

read -p "💬 Enter the path to the backup file (example: ./backups/couchbase-backup-20251019-132334.tar.gz): " BACKUP_FILE

if [ -z "$BACKUP_FILE" ] || [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Invalid backup file!"
    exit 1
fi

# === Temporary directory ===
TEMP_DIR="./temp_restore"
rm -rf "${TEMP_DIR}" 2>/dev/null || true
mkdir -p "${TEMP_DIR}"
echo "📁 Temporary directory created: ${TEMP_DIR}"

# === Extract backup ===
echo "📦 Extracting backup file..."
tar -xzf "${BACKUP_FILE}" -C "${TEMP_DIR}" || {
    echo "❌ Failed to extract backup file!"
    rm -rf "${TEMP_DIR}"
    exit 1
}

# === Validate backup structure ===
if [ ! -d "${TEMP_DIR}/repo" ]; then
    echo "❌ 'repo' directory not found in backup!"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

# === Copy backup files into container ===
echo "📁 Copying backup files into container..."
docker exec ${CONTAINER_NAME} mkdir -p /backups
docker cp "${TEMP_DIR}/repo" ${CONTAINER_NAME}:/backups/ || {
    echo "❌ Failed to copy backup files into container!"
    rm -rf "${TEMP_DIR}"
    exit 1
}

# === Start restore ===
echo "🚀 Starting Couchbase restore..."
docker exec ${CONTAINER_NAME} cbbackupmgr restore \
  --archive /backups/repo \
  --repo ${CB_REPO_NAME} \
  --cluster ${CB_CLUSTER_URL} \
  --username ${CB_USERNAME} \
  --password ${CB_PASSWORD} \
  --force-updates || {
    echo "❌ Restore failed!"
    rm -rf "${TEMP_DIR}"
    exit 1
  }

# === Cleanup ===
echo "🧹 Cleaning up temporary files..."

if [ -d "${TEMP_DIR}" ]; then
  chmod -R 777 "${TEMP_DIR}" 2>/dev/null || true
  rm -rf --one-file-system "${TEMP_DIR}" 2>/dev/null || true
  sleep 1
  rm -rf --one-file-system "${TEMP_DIR}" 2>/dev/null || true
fi

echo
echo "✅ Restore completed successfully!"
echo "🎉 Couchbase container restored: ${CONTAINER_NAME}"
