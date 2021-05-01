#!/bin/bash

archive_uuid=060a826e-d440-4517-b349-9b33126e0ba3

plex_drive=$(lsblk | grep plex | cut -d' ' -f1)
plex_uuid=$(ls -lah /dev/disk/by-uuid/ | grep $plex_drive | cut -d' ' -f11)

# check archive drive status, hopefully asleep or standby
hdparm -C /dev/disk/by-uuid/$archive_uuid

echo "Mounting $archive_uuid.."
mount --uuid $archive_uuid /archive

# -a https://serverfault.com/questions/141773/what-is-archive-mode-in-rsync
# --delete                delete extraneous files from destination dirs
echo "Begin rsync..."
rsync -a --delete /plex/ /archive

echo "Unmounting and sleeping"
umount --uuid $archive_uuid /archive && hdparm -Y /dev/disk/by-uuid/$archive_uuid
echo "Done."
