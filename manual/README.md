# Manual Couchbase Docker Backup and Restore Guide

This guide explains how to manually backup and restore a Couchbase database running in a Docker container. For automatic backup solution, please check the `automatic` folder.

## Requirements

- Docker installed on your system
- Running Couchbase Docker container
- Sufficient disk space for backups

## Backup Process

Use the `backup.sh` script for manual backup:

```bash
./backup.sh <container_name> <backup_directory>
```

Example:
```bash
./backup.sh couchbase-server /backup/couchbase
```

What this command does:
1. Initiates backup process in the specified Couchbase container
2. Backs up all buckets
3. Saves backups to the specified directory

## Restore Process

Use the `restore.sh` script for manual restore:

```bash
./restore.sh <container_name> <backup_directory>
```

Example:
```bash
./restore.sh couchbase-server /backup/couchbase
```

What this command does:
1. Reads data from the specified backup directory
2. Restores data to the Couchbase container

## Important Notes

- Ensure sufficient disk space before starting backup
- Make sure target buckets exist before restore
- Couchbase service must be running during operations
- This is a manual backup solution - for automated backups, use the scripts in the `automatic` folder

## Troubleshooting

If you encounter any errors:
1. Check script outputs
2. Verify Couchbase container is running
3. Check disk space and permissions
4. Ensure correct container name is provided

## Security Best Practices

- Secure your backup directories
- Restrict access to backup files
- Regularly verify backup integrity
- Keep backup scripts in a secure location

## Directory Structure

```
couchbase-docker-backup/
├── manual/           # Manual backup scripts (current folder)
│   ├── backup.sh    # Manual backup script
│   ├── restore.sh   # Manual restore script
│   └── README.md    # This guide
└── automatic/       # Automated backup solution (coming soon)
```

## Next Steps

- For automated backups with scheduling and retention policies, check the `automatic` folder (upcoming)
- The automatic solution will include features like:
  - Scheduled backups
  - Backup rotation
  - Email notifications
  - Error handling
  - Logging