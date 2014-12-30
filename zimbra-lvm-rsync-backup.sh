#!/bin/bash
  
time=`date +%Y-%m-%d`

# Modify the following variables according to your installation
###############################################################

# backup_dir - directory to backup to
backup_dir=FULL-PATH-TO-BACKUP-DIR

# backup_log - path to backup log file e.g. /var/log/zimbra-backup.log
backup_log=FULL-PATH-BACKUP-LOG-FILE

# vol_group - the Volume Group that contains $zimbra_vol
vol_group=VOLUMN-GROUP-NAME

# zimbra_vol - the Logical Volume that contains /opt/zimbra
zimbra_vol=LOGICAL-VOLUMN-NAME

# zimbra_vol_fs - the file system type (ext3, ext4, xfs, ...) in /opt/zimbra
zimbra_vol_fs=FILE-SYSTEM-TYPE

# zimbra_backup_vol - the Logical Volume for zimbra_vol snapshot
zimbra_backup_vol=LOGICAL-VOLUMN-NAME

# zimbra_backup_volsize - the size of snapshot
zimbra_backup_volsize=BACKUP-VOLUMN-SIZE

# lvcreate and lvremove commands path
lvcreate_cmd=/usr/sbin/lvcreate
lvremove_cmd=/usr/sbin/lvremove

# rsync command path
rsync_cmd=/usr/bin/rsync

# incremental backup directory that contains new/modified/deleted data on the local machine. This will fill up over time!
incremental_backup_dir=/opt/backup/zimbra/<dir-name-containing-incremental-backups>/$(date +%F-%H-%M-%S)

# destination directory for full backup
full_backup_dir=$backup_dir/<dir-name-containing-full-backup>

# email address and email command path defination
email="<your-email-address>"
mail_cmd=/bin/mail
  
# Do not change anything beyond this point
##########################################

# Output date
echo "`date +"%Y-%m-%d %H:%M:%S"` Backups started at `date`." >> $backup_log

# Create a logical volume called $zimbra_backup_vol
echo "`date +"%Y-%m-%d %H:%M:%S"` Creating a LV called $zimbra_backup_vol..." >> $backup_log
$lvcreate_cmd -L$zimbra_backup_volsize -s -n $zimbra_backup_vol /dev/$vol_group/$zimbra_vol

# Create a mountpoint to mount the logical volume to
echo "`date +"%Y-%m-%d %H:%M:%S"` Creating a mountpoint for the LV..." >> $backup_log
# WARNING: this is insecure!
mkdir -p /tmp/$zimbra_backup_vol

# Mount the logical volume to the mountpoint
echo "`date +"%Y-%m-%d %H:%M:%S"` Mounting the LV..." >> $backup_log
# WARNING: use nouuid option if the filesystem is formatted as XFS
mount -t $zimbra_vol_fs -o ro /dev/$vol_group/$zimbra_backup_vol /tmp/$zimbra_backup_vol/

# Sync email data to the full backup directory daily
echo "`date +"%Y-%m-%d %H:%M:%S"` Creating the full backup directory and syncing mail data..." >> $backup_log
$rsync_cmd -aHKS --delete --backup --backup-dir=$incremental_backup_dir /tmp/$zimbra_backup_vol/zimbra/ $full_backup_dir/zimbra

# Unmount /tmp/$zimbra_backup_vol and remove the logical volume
echo "`date +"%Y-%m-%d %H:%M:%S"` Unmounting and removing the LV..." >> $backup_log
umount /tmp/$zimbra_backup_vol/
$lvremove_cmd --force /dev/$vol_group/$zimbra_backup_vol
rmdir /tmp/$zimbra_backup_vol/

# Send email report automatically after backup
msg="Zimbra Backup sucessfully synced to the directory $full_backup_dir/zimbra at `date`."
subject="Securemail - Result of Daily Zimbra Backup $time"
echo "$msg" | $mail_cmd -s "$subject" "$email"

# Done!
