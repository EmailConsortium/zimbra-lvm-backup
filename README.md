zimbra-lvm-backup
=================

Script to backup Zimbra on a dedicated LVM logical volumn.

This script has been improved from the old one discussed on Zimbra community to have abilities to run scheduled backup as a cronjob, make incremental backups to make a full backup daily via rsync, send email report automatically after backup, and add some more parameters as well.

One of the coolest things is NO system downtime; recommended to use in production environments.

The program is released under terms of GPL v3.0. See COPYING for more information.

See INSTALL for how to use the program.

All suggestions, ideas and contributions are welcome. Please contact me at tatuan [at] gmail [dot] com at anytime.
