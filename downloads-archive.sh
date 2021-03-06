#!/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
# debug output
#set -x
date
# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT

# UUID of the archive drive:
archive_uuid='060a826e-d440-4517-b349-9b33126e0ba3'
# UUID of the main plex drive:
main_uuid='a5bda2f6-926f-4a36-8f76-55635c3dcb4f'

# grep returns a 1 if there were no matches
lsblk | grep -qs '/archive'
if [ $? -eq 0 ]; then
    echo "Error, archive already mounted! Is this the last run still going?"
    exit 1
fi
lsblk | grep plex
if [ $? -eq 1 ]; then
    mount /dev/disk/by-uuid/$main_uuid /plex
fi


# exit when any command fails
set -e

fsck -n /dev/disk/by-uuid/$main_uuid
fsck -n /dev/disk/by-uuid/$archive_uuid

# Check status, should take a bit to kick it out of deep sleep mode.
hdparm -C /dev/disk/by-uuid/$archive_uuid

# Mount the archive drive. Will take a bit as the drive should be in standby mode.
mount /dev/disk/by-uuid/$archive_uuid /archive
# Just throw in a check for the main drive uuid in case it's not mounted or something
# like if shit is broke and I don't notice for a week or a month.


# Copy and delete things that don't exist on the source.
/usr/bin/rsync -aq --delete /plex/ /archive/
#echo "Would have ran rsync"
if [ $? -eq 0 ]; then
    echo "Rsync completed."
else
    echo "Rsync returned non-zeo exit status: $?"
fi

umount /archive

# Get the total spin-up time. Need to check this before putting in standby mode.
smartctl -a /dev/disk/by-uuid/$archive_uuid | grep Spin_Up_Time

# Place drive into standby mode, should cause it to spin down.
# -Y is lowest power mode.
# -y is standby while still powered?
hdparm -y /dev/disk/by-uuid/$archive_uuid
sleep 5
hdparm -Y /dev/disk/by-uuid/$archive_uuid

#fin
