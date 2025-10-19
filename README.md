# Couchbase Docker Backup Solutions

This repository contains both manual and automated backup solutions for Couchbase running in Docker containers.

## Features

- **Manual Backup Solution**
  - Simple shell scripts for backup and restore
  - Step-by-step documentation
  - Suitable for one-time or on-demand backups

- **Automated Backup Solution** (Coming Soon)
  - Scheduled backups
  - Backup rotation and retention policies
  - Email notifications
  - Error handling and logging

## Project Structure

```
couchbase-docker-backup/
├── manual/           # Manual backup solution
│   ├── backup.sh    # Manual backup script
│   ├── restore.sh   # Manual restore script
│   └── README.md    # Manual backup guide
└── automatic/       # Automated backup solution (coming soon)
```

## Quick Start

### Manual Backup
For manual backup and restore operations, check the [manual backup guide](manual/README.md).

### Automated Backup
Automated backup solution is coming soon. It will include scheduling, retention policies, and notifications.

## Requirements

- Docker
- Running Couchbase container
- Bash shell environment
- Sufficient disk space for backups

## Contributing

Feel free to open issues and pull requests for any improvements.

## License

MIT License - feel free to use and modify for your needs.