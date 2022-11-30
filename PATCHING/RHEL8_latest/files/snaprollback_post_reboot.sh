#!/bin/bash
#
# v1.0 Roger Sims : First release
# Logs to stdout for ansible and to local logs

logdir=/var/log
shortdate=`date +%d%m%y`
update_log=$logdir/"OS_update_log_"$shortdate".out"
timestamp() {
  date +"%T:%d%m%y" # use with $(timestamp)
}

echo "################################################" >> $update_log 2>&1

echo "INFO : $(timestamp) Starting post-rollback actions to cleanup old LVM links" >> $update_log 2>&1
echo "INFO : $(timestamp) Starting post-rollback actions to cleanup old LVM links"

systemctl restart lvm2-monitor.service >> $update_log 2>&1
snap_count=`ls -l /dev/mapper | grep -w snap | wc -l`
if [ $snap_count = 0 ]
then
  echo "INFO : $(timestamp) post reboot actions run sucessfully" >> $update_log 2>&1
  echo "INFO : $(timestamp) post reboot actions run sucessfully"
else
  echo "ERROR : $(timestamp) LVM /dev/mapper entries related to snaps still exist, please contact engineering before retrying patching" >> $update_log 2>&1
  echo "ERROR : $(timestamp) LVM /dev/mapper entries related to snaps still exist, please contact engineering before retrying patching"
  exit 1
fi

