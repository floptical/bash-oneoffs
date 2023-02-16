#!/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
# debug output
#set -x

datevar=$(date)
echo ""
echo -e "\nStarting script at $datevar."
# UUID of the archive drive:
#archive_uuid='060a826e-d440-4517-b349-9b33126e0ba3'
# UUID of the main plex drive:
#main_uuid='a5bda2f6-926f-4a36-8f76-55635c3dcb4f'

# Main LVM device
main_mount=/dev/mapper/combined-combined_mount
# Backup LVM device
backup_mount=/dev/mapper/combined_backup-combined_backup_mount

# UUIDS found with blkid not working for smartctl/hdparm operations
# Bceause they're not listed in /dev/disk/by-uuid
# I think they also change on boot too??
#backup_drive_1_uuid="B4JZYJ-cu9e-IW07-0AYz-l9sL-1MIq-C3FHXg"
#backup_drive_2_uuid="Eo2XFf-nHsQ-V0Hd-1MOE-K1F1-JeK6-E3rxfu"
backup_drive_1=/dev/sdd
backup_drive_2=/dev/sde
# grep returns a 1 if there were no matches
pgrep -a rsync && echo "Rsync process still running!" && exit 1
pgrep -a rsync || echo "No rsync processes running, continuing"

umount /backup

# grep returns a 1 if there were no matches
lsblk | grep -qs '/backup'
if [ $? -eq 0 ]; then
    echo "Error, backup already mounted! Is this the last run still going?"
    exit 1
fi

# mount plex if not mounted.
lsblk | grep plex
if [ $? -eq 1 ]; then
    mount $main_mount /plex
fi

# exit when any command fails
set -e
echo "Running fsck on main plex drive."
fsck.ext4 -n $main_mount
echo "Running fsck on the secondary archive drive."
fsck.ext4 -n $backup_mount

# Check status, should take a bit to kick it out of deep sleep mode.
hdparm -C $backup_drive_1
hdparm -C $backup_drive_2

# Mount the archive drive. Will take a bit as the drive should be in standby mode.
mount $backup_mount /backup

datevar=$(date)
echo "Starting rsync at $datevar..."
# Copy and delete things that don't exist on the source.
/usr/bin/rsync --stats -aq --delete /plex/ /backup/
if [ $? -eq 0 ]; then
    datevar=$(date)
    echo "Rsync completed at $datevar."
else
    datevar=$(date)
    echo "Rsync returned non-zeo exit status: $? at $datevar"
fi

umount /backup

# Get the total spin-up time. Need to check this before putting in standby mode.
smartctl -a $backup_drive_1 | grep Spin_Up_Time
smartctl -a $backup_drive_2 | grep Spin_Up_Time

# Place both backup LVM drives into standby mode, should cause it to spin down.
# sleep mode doesn't work for my LVM disks, maybe because of the yottamaster
# they're mounted in.
# -Y is lowest power mode.
# -y is standby while still powered?
hdparm -y $backup_drive_1
hdparm -y $backup_drive_2

# Don't forget to modify smartd so it doesn't cause standby disks to power back on:
# https://superuser.com/a/1391944

echo "finished."
