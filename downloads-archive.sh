#!/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
# exit when any command fails
set -e
# debug output
set -x

# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT

LogMsg()
{
  LogFile=/var/log/download-archives.log
  if [ -n "$1" ]
  then
      IN="$1"
  else
      read IN # This reads a string from stdin and stores it in a variable called IN
  fi

  DateTime=`date "+%Y/%m/%d %H:%M:%S"`
  echo '*****'$DateTime' ('$QMAKESPEC'): '$IN >> "$LogFile"
  echo $DateTime' ('$QMAKESPEC'): '$IN
}

# UUID of the archive drive:
archive_uuid='060a826e-d440-4517-b349-9b33126e0ba3'
main_uuid='a5bda2f6-926f-4a36-8f76-55635c3dcb4f'

# Check status, should take a bit to kick it out of deep sleep mode.
hdparm -C /dev/disk/by-uuid/$archive_uuid 2>&1 | LogMsg

# Mount the archive drive. Will take a bit as the drive should be in standby mode.
mount /dev/disk/by-uuid/$archive_uuid /archive 2>&1 | LogMsg
# Just throw in a check for the main drive uuid in case it's not mounted or something
# like if shit is broke and I don't notice for a week or a month.
mount /dev/disk/by-uuid/$main_uuid /plex 2>&1 | LogMsg

# Copy and delete things that don't exist on the source.
/usr/bin/rsync -aq --delete /plex/ /archive/ 2>&1 | LogMsg
if [ $? -eq 0 ]; then
    echo "Rsync completed."
else
    echo "Rsync returned non-zeo exit status: $?"
fi

#Set to low power standby mode. -Y would completely spin it down and it takes much longer to start back up
umount /archive 2>$1 | LogMsg

# Get the total spin-up time. Need to check this before putting in standby mode.
smartctl -a /dev/disk/by-uuid/$archive_uuid | grep Spin_Up_Time 2>&1 | LogMsg

# Place drive into standby mode, should cause it to spin down.
# -Y is lowest power mode.
# -y is standby while still powered?

hdparm -Y /dev/disk/by-uuid/$archive_uuid 2>&1 | LogMsg
# Check status
hdparm -C /dev/disk/by-uuid/$archive_uuid 2>&1 | LogMsg

