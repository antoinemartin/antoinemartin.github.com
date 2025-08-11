---
title: Transferring WSL Home Directories Between Distributions
date: 2025-08-11
slug: 2025/08/11/transferring-wsl-home-directories-between-distributions
description: |
    A practical approach to migrate your development environment between WSL distributions using rsync
Categories:
    - Development
tags:
    - wsl
    - linux
    - migration
    - rsync
    - windows
toc:
    enable: true
---

When upgrading to a new version of a Linux distribution in WSL or switching
between different distributions, transferring your carefully configured home
directory can be a challenge. This post presents a practical solution using
rsync and WSL's inter-distribution mounting capabilities to seamlessly transfer
your development environment.

<!-- more -->

## The Challenge

WSL distributions are isolated from each other, making it difficult to transfer
files directly. Traditional backup and restore approaches using tar archives
work but have limitations:

-   They create large archive files that consume disk space
-   The process is not incremental - you can't easily update an existing
    transfer
-   Recovery from interruptions requires starting over

## The Solution: Live Directory Synchronization

The approach presented here leverages WSL's ability to mount directories from
one distribution into another, combined with rsync's powerful synchronization
capabilities. This method offers several advantages:

-   **Incremental transfers**: Only changed files are transferred on subsequent
    runs
-   **Resumable**: Interrupted transfers can be resumed without starting over
-   **Real-time**: Can be used for ongoing synchronization
-   **Selective**: Automatically excludes temporary and cache directories

## How It Works

The solution involves three steps:

1. **Mount the source directory** from the source WSL distribution
2. **Run the sync script** in the destination distribution
3. **Transfer with intelligent exclusions** to avoid unnecessary files

## The Script

I've created a dedicated script for this purpose:
[`sync_wsl_directory.sh`](/downloads/code/sync_wsl_directory.sh)

The core synchronization logic uses rsync with carefully chosen options:

```bash
# Define exclusions for common cache and temporary directories
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

# Execute rsync with preservation of permissions and attributes
rsync $RSYNC_OPTS $RSYNC_EXCLUDES "$SOURCE_DIR/" "$DEST_DIR/"
```

The script uses rsync options that preserve:

-   File permissions and ownership (`-a`)
-   Hard links (`-H`)
-   Extended attributes (`-A`)
-   Access control lists (`-X`)
-   Sparse files (`-S`)
-   Numeric user/group IDs (`--numeric-ids`)

## Step-by-Step Transfer Process

### 1. Prepare the Source Distribution

Connect to your source WSL distribution as root and create a mount point:

```bash
# In source WSL distribution (e.g., Ubuntu 20.04)
sudo su -
mkdir -p /mnt/wsl/from
mount --bind /home/yourusername /mnt/wsl/from
```

This makes your home directory accessible from other WSL distributions.

### 2. Prepare the Destination Distribution

Connect to your destination WSL distribution and obtain the sync script:

```bash
# In destination WSL distribution (e.g., Ubuntu 24.04)
sudo su -

# Option 1: Download directly
curl -o sync_wsl_directory.sh https://mrtn.me/downloads/code/sync_wsl_directory.sh
chmod +x sync_wsl_directory.sh

# Option 2: Copy from Windows filesystem (if you've saved it there)
cp /mnt/c/path/to/sync_wsl_directory.sh .
chmod +x sync_wsl_directory.sh
```

### 3. Preview the Transfer (Recommended)

Before performing the actual transfer, run a dry-run to see what will be
transferred:

```bash
./sync_wsl_directory.sh -n -v /mnt/wsl/from /home/yourusername
```

This shows you exactly what files will be copied without actually performing the
transfer.

### 4. Perform the Transfer

Execute the actual synchronization:

```bash
./sync_wsl_directory.sh /mnt/wsl/from /home/yourusername
```

For a more cautious approach that removes files in the destination that don't
exist in the source:

```bash
./sync_wsl_directory.sh -d /mnt/wsl/from /home/yourusername
```

## Why These Exclusions?

The script excludes several directory types that are typically not needed when
transferring to a new environment:

-   **`.cache/`**: Application cache files that will be regenerated
-   **`.vscode-server/`**: VS Code server files specific to the old distribution
-   **`go/`**: Go workspace that may contain OS-specific binaries
-   **`.tenv/`**: Terraform version manager cache
-   **`.local/share/Trash/`**: Deleted files that don't need to be transferred
-   **Temporary files**: `.tmp/`, `.temp/`, `*.log`, `*.pid`

These exclusions significantly reduce transfer time and avoid carrying over
potentially incompatible cached data.

## Advanced Usage

### Ongoing Synchronization

The script can be run multiple times to keep directories in sync. This is useful
when:

-   Testing the new distribution while still working on the old one
-   Gradually migrating your workflow
-   Maintaining backup copies

### Custom Exclusions

You can modify the `RSYNC_EXCLUDES` variable in the script to add your own
exclusions based on your specific setup.

### Verbose Output

Use the `-v` flag to see detailed information about what's being transferred:

```bash
./sync_wsl_directory.sh -v /mnt/wsl/from /home/yourusername
```

## Best Practices

1. **Always run a dry-run first** to preview the transfer
2. **Ensure adequate disk space** in the destination distribution
3. **Stop running applications** in both distributions during transfer
4. **Verify the transfer** by checking key configuration files
5. **Keep the script handy** by saving it to your Windows filesystem for reuse

## Script Availability

The script is available [here](/downloads/code/sync_wsl_directory.sh).

You can either download it directly in your WSL distribution or save it to your
Windows filesystem for repeated use across different distributions.

## Conclusion

This approach provides a robust, flexible solution for transferring development
environments between WSL distributions. The use of rsync ensures efficient,
resumable transfers while the intelligent exclusions prevent unnecessary data
from cluttering your new environment.

Whether you're upgrading to a new Ubuntu LTS or Alpine release, trying out a
different distribution, or simply want to maintain synchronized development
environments, this method offers a practical alternative to traditional backup
and restore procedures.
