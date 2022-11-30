#!/bin/bash
#
# Removal of OpenOnload content from machines in question
# Will need expansion to remove other content
#
# v1.0 Roger Sims 12 OCt : First release
# Logs to stdout for ansible and to local logs

logdir=/var/log
shortdate=`date +%d%m%y`
update_log=$logdir/"OS_update_log_"$shortdate".out"
timestamp() {
  date +"%T:%d%m%y" # use with $(timestamp)
}

echo "################################################" >> $update_log 2>&1
echo "INFO : $(timestamp) Starting rollback_validate.sh"
echo "INFO : $(timestamp) Starting rollback_validate.sh"  >> $update_log 2>&1

echo "Printing LVS seen " >> $update_log 2>&1
/sbin/lvs >> $update_log 2>&1

snapdetect=`/sbin/lvs root_vg | grep snap | wc -l` >> $update_log 2>&1
if [ "$snapdetect" -ge 1 ]
then
  echo "INFO : Great news, we have root_vg snapshots, rollback possible"  >> $update_log 2>&1
  echo "" >> $update_log 2>&1
  echo "INFO : Great news, we have root_vg snapshots, rollback possible"
else
  echo "INFO : No root snaps detected, cannot continue, EXITING" >> $update_log 2>&1
  echo "" >> $update_log 2>&1
  echo "INFO : No root snaps detected, cannot continue, EXITING"
  exit 1
fi

if [ -d /var/backup/boot ]
then
  initramfs_count=`ls -1 /var/backup/boot/initramfs* | wc -l`
  if [ $initramfs_count -eq 0 ]
  then
    echo "ERROR : $(timestamp) DID NOT FIND ANY BACKUP INITRAMFS, BOOT BACKUP IS SUSPECT!!!" >> $update_log 2>&1
    echo "ERROR : $(timestamp) DID NOT FIND ANY BACKUP INITRAMFS, BOOT BACKUP IS SUSPECT!!!"
    exit 1
  fi
else
  echo "ERROR : $(timestamp) Did not find /var/backup/boot" >> $update_log 2>&1
  echo "ERROR : $(timestamp) Did not find /var/backup/boot"
  exit 1
fi

# Not sure of the value of checking the exit status as it shows we cannot merge until after reboot
for i in `lvs | grep snap | awk '{print $1}'`
  do /sbin/lvconvert --merge /dev/root_vg/$i  >> $update_log 2>&1
done

root_dev=`/sbin/pvs | grep root_vg | grep sda | wc -l`
if [ "$root_dev" -ge 1 ]
then
  echo "INFO : $(timestamp) Detected root on /dev/sda, Rolling back now" >> $update_log 2>&1
  echo "INFO : $(timestamp) Detected root on /dev/sda, Rolling back now" 
  /bin/rm -rf /boot/* >> $update_log 2>&1
  /bin/cp -r /var/backup/boot/* /boot >> $update_log 2>&1
  /sbin/grub2-install /dev/sda >> $update_log 2>&1
  if [ $? -ne 0 ]
  then
    echo "ERROR : $(timestamp) PLEASE DO NOT REBOOT, grub-install errored, please check the state of the machine" >> $update_log 2>&1
    exit 1
  fi
else
  echo "ERROR : $(timestamp) Did not find root_vg on /dev/sda, is this box unusual? Needs intervention/manual recovery"
  echo "ERROR : $(timestamp) Did not find root_vg on /dev/sda, is this box unusual? Needs intervention/manual recovery"
  exit 1
fi

echo "INFO : $(timestamp) Completion of rollback script. Please check /var/log Logs content" >> $update_log 2>&1
echo "INFO : $(timestamp) Completion of rollback script. Please check /var/log Logs content"
echo "################################################" >> $update_log 2>&1

