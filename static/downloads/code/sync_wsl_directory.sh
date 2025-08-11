#!/usr/bin/env sh

# cSpell: ignore rsync

# Script to sync directories between WSL distributions using rsync
# This script is designed to be run in the destination WSL distribution
# while the source directory is mounted from another distribution

# Parse command line arguments
SOURCE_DIR=""
DEST_DIR=""
DRY_RUN=false
VERBOSE=false
DELETE=false

show_usage() {
    echo "Usage: $(basename "$0") [OPTIONS] SOURCE_DIR DEST_DIR"
    echo "Sync directories between WSL distributions using rsync"
    echo ""
    echo "Arguments:"
    echo "  SOURCE_DIR    Source directory (e.g., /mnt/wsl/from)"
    echo "  DEST_DIR      Destination directory (e.g., /home/user)"
    echo ""
    echo "Options:"
    echo "  -n, --dry-run     Show what would be transferred without actually doing it"
    echo "  -v, --verbose     Enable verbose output"
    echo "  -d, --delete      Delete files in destination that don't exist in source"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") /mnt/wsl/from /home/user"
    echo "  $(basename "$0") -n -v /mnt/wsl/from /home/user  # Dry run with verbose output"
    echo "  $(basename "$0") -d /mnt/wsl/from /home/user     # Sync with deletion"
    echo ""
    echo "Setup workflow:"
    echo "1. In source WSL distribution (as root):"
    echo "   mkdir -p /mnt/wsl/from"
    echo "   mount --bind /home/user /mnt/wsl/from"
    echo "2. In destination WSL distribution (as root):"
    echo "   $(basename "$0") /mnt/wsl/from /home/user"
}

while [ $# -gt 0 ]; do
    case $1 in
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -d|--delete)
            DELETE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            echo "Error: Unknown option $1"
            show_usage
            exit 1
            ;;
        *)
            if [ -z "$SOURCE_DIR" ]; then
                SOURCE_DIR="$1"
            elif [ -z "$DEST_DIR" ]; then
                DEST_DIR="$1"
            else
                echo "Error: Too many arguments"
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate arguments
if [ -z "$SOURCE_DIR" ] || [ -z "$DEST_DIR" ]; then
    echo "Error: Both source and destination directories must be specified"
    show_usage
    exit 1
fi

# Test if the user is root and exit if this is not the case
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root to preserve ownership and permissions"
    exit 1
fi

# Check that rsync is installed
if ! command -v rsync >/dev/null 2>&1; then
    echo "Error: rsync is not installed"
    echo "Install it with: apt update && apt install rsync"
    exit 1
fi

# Validate source directory
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory '$SOURCE_DIR' not found"
    echo "Make sure the source directory is properly mounted:"
    echo "  mkdir -p /mnt/wsl/from"
    echo "  mount --bind /path/to/source /mnt/wsl/from"
    exit 1
fi

# Create destination directory if it doesn't exist
if [ ! -d "$DEST_DIR" ]; then
    echo "Creating destination directory: $DEST_DIR"
    mkdir -p "$DEST_DIR"
fi

# Build rsync command with options
RSYNC_OPTS="-aHAXS --numeric-ids"

# Add verbose option if requested
if [ "$VERBOSE" = true ]; then
    RSYNC_OPTS="$RSYNC_OPTS -v"
fi

# Add dry-run option if requested
if [ "$DRY_RUN" = true ]; then
    RSYNC_OPTS="$RSYNC_OPTS --dry-run"
    echo "DRY RUN MODE - No files will be actually transferred"
fi

# Add delete option if requested
if [ "$DELETE" = true ]; then
    RSYNC_OPTS="$RSYNC_OPTS --delete"
    echo "DELETE MODE - Files in destination not present in source will be removed"
fi

# Add progress unless in dry-run mode
if [ "$DRY_RUN" != true ]; then
    RSYNC_OPTS="$RSYNC_OPTS --progress"
fi

# Define exclusions (same as the original script)
RSYNC_EXCLUDES="
--exclude=.cache/
--exclude=.vscode-server/
--exclude=go/
--exclude=.tenv/
--exclude=.local/share/Trash/
--exclude=.tmp/
--exclude=.temp/
--exclude=*.log
--exclude=*.pid
--exclude=.nohup.out
"

echo "Syncing from: $SOURCE_DIR"
echo "Syncing to:   $DEST_DIR"
echo "Options:      $RSYNC_OPTS"
echo ""

# Execute rsync
# shellcheck disable=SC2086
if rsync $RSYNC_OPTS $RSYNC_EXCLUDES "$SOURCE_DIR/" "$DEST_DIR/"; then
    if [ "$DRY_RUN" = true ]; then
        echo ""
        echo "Dry run completed successfully"
        echo "Run without -n/--dry-run to perform the actual sync"
    else
        echo ""
        echo "Sync completed successfully"
        
        # Show some statistics
        echo "Destination directory size:"
        du -sh "$DEST_DIR" 2>/dev/null | cut -f1 || echo "Unable to calculate size"
    fi
else
    echo ""
    echo "Error: Sync failed with exit code $?"
    exit 1
fi
