#!/bin/bash
# Utande Billing — SQLite backup script
# Usage: ./backup.sh [backup-dir]

BACKUP_DIR="${1:-./backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_DIR="$(dirname "$0")/prisma"
DB_FILE="$DB_DIR/dev.db"
DB_WAL="$DB_DIR/dev.db-wal"

mkdir -p "$BACKUP_DIR"

if [ ! -f "$DB_FILE" ]; then
  echo "Database not found at $DB_FILE"
  exit 1
fi

# Use sqlite3 to create a consistent snapshot
if command -v sqlite3 &>/dev/null; then
  sqlite3 "$DB_FILE" ".backup '$BACKUP_DIR/utande_$TIMESTAMP.db'"
else
  cp "$DB_FILE" "$BACKUP_DIR/utande_$TIMESTAMP.db"
  [ -f "$DB_WAL" ] && cp "$DB_WAL" "$BACKUP_DIR/utande_$TIMESTAMP.db-wal"
fi

# Keep only last 30 backups
ls -t "$BACKUP_DIR"/utande_*.db 2>/dev/null | tail -n +31 | xargs -r rm

echo "Backup saved: $BACKUP_DIR/utande_$TIMESTAMP.db"
