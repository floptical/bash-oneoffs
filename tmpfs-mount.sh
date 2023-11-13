#!/bin/bash
set -e

# Create and mount a tmpfs device for communicating secrets
# tmpfs is a RAM device, so theoretically if someone maliciously imaged
# the underlying filesystem, they wouldn't get whatever is in here.
# https://www.kernel.org/doc/html/latest/filesystems/tmpfs.html

current_user=$(whoami)

# Only allow this setup to work with a user that has sudo privs.
# Keeps setup specific to higher-level user and allows us to mount the device at the end.
if sudo -l -U "$current_user" 2>&1 | grep -q "is not allowed to run sudo on"; then
    echo "User $current_user does not have sudo privileges, please run as a user that does."
fi

MOUNT_DIR="/tmpfs-secure"
TMPFS_SIZE="10M"

# Check if the directory exists
if [ ! -d "$MOUNT_DIR" ]; then
    echo "Directory $MOUNT_DIR does not exist. Creating it..."
    mkdir -p "$MOUNT_DIR"
    if [ $? -ne 0 ]; then
        echo "Failed to create directory $MOUNT_DIR"
        return 1
    fi
fi

# Failsafe in case we don't get proper user with whoami for some reason
if [ $(id -u $current_user) -eq 0 ]; then
    echo "Cannot mount with a UID of 0, something's gone wrong?"
fi
if [ $(id -g $current_user) -eq 0 ]; then
    echo "Cannot mount with a GID of 0, something's gone wrong?"
fi

# Mount tmpfs on the specified directory
if ! grep -q "$MOUNT_DIR" /etc/fstab; then
    echo "Mounting $MOUNT_DIR with privs only for $current_user UID: $(id -u $current_user)"
    echo "tmpfs $MOUNT_DIR tmpfs size=$TMPFS_SIZE,mode=0700,uid=$(id -u $current_user),gid=$(id -g $current_user) 0 0" | sudo tee -a /etc/fstab
else
    echo 'tmpfs already in fstab.'
fi

if mount | grep -q 'tmpfs-secure'; then
    echo '/tmpfs-secure already mounted.'
else
    echo 'Mounting /tmpfs-secure..'
    sudo mount "$MOUNT_DIR"
fi
