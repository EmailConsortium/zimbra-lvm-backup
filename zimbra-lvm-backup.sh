#!/bin/bash

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
  
time=`date +%Y-%m-%d_%H-%M-%S`

# Modify the following variables according to your installation
#########################################

# backup_dir - directory to backup to
backup_dir=FULL-PATH-TO-BACKUP-DIR

# vol_group - the Volume Group that contains $zimbra_vol
vol_group=VOLUMN-GROUP-NAME

# zimbra_vol - the Logical Volume that contains /opt/zimbra
zimbra_vol=LOGICAL-VOLUMN-NAME

# zimbra_vol_fs - the file system type (ext3, ext4, xfs, ...) in /opt/zimbra
zimbra_vol_fs=FILE-SYSTEM-TYPE

# zimbra_backup_vol - the Logical Volume for zimbra_vol snapshot
zimbra_backup_vol=LOGICAL-VOLUMN-NAME

# zimbra_backup_volsize - the size of snapshot: 1000M, 2G, etc.
zimbra_backup_volsize=BACKUP-VOLUMN-SIZE

# lvcreate and lvremove commands path - checking by `which lvcreate`
lvcreate_cmd=/sbin/lvcreate
lvremove_cmd=/sbin/lvremove

# number of backups retained - should be >0
# WARNING: 0 meant do not retain any backup, include the most newly created one
number_of_backups_retain=NUMBER-OF-BACKUPS-RETAINED
  
# Do not change anything beyond this point
#########################################

# Output date
echo "Backup started at `date`."

# Stop the Zimbra services
echo "Stopping the Zimbra services..."
/etc/init.d/zimbra stop

# Create a logical volume called $zimbra_backup_vol
echo "Creating a LV called $zimbra_backup_vol:"
$lvcreate_cmd -L$zimbra_backup_volsize -s -n $zimbra_backup_vol /dev/$vol_group/$zimbra_vol

# Create a mountpoint to mount the logical volume to
echo "Creating a mountpoint for the LV..."
# WARNING: this is insecure!
mkdir -p /tmp/$zimbra_backup_vol

# Mount the logical volume to the mountpoint
echo "Mounting the LV..."
# WARNING: use nouuid option if the filesystem is formatted as XFS
mount -t $zimbra_vol_fs -o ro /dev/$vol_group/$zimbra_backup_vol /tmp/$zimbra_backup_vol/

# Start the Zimbra services
echo "Starting the Zimbra services..."
# WARNING: it's safer not to put this command in background
/etc/init.d/zimbra start &

# Create the current backup
echo "Creating the backup directory and backup..."
tar zcvf $backup_dir/zimbra-backup-$time.tar.gz /tmp/$zimbra_backup_vol/zimbra/ 2&> /dev/null

# Unmount /tmp/$zimbra_backup_vol and remove the logical volume
echo "Unmounting and removing the LV."
umount /tmp/$zimbra_backup_vol/
$lvremove_cmd --force /dev/$vol_group/$zimbra_backup_vol
rmdir /tmp/$zimbra_backup_vol/

# Remove the old backups
echo "Removing the old backups..."
find $backup_dir -mtime $number_of_backups_retain -delete

# Done!
echo "Zimbra backed up to $backup_dir/zimbra-backup-$time.tar.gz"
echo "Backup ended at `date`."
