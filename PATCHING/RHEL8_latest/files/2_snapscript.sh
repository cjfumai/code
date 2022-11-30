#!/bin/bash
#
# Assumptions are made the validation script has proved issues like root_vg snap space
# and /boot and /var space issues are looked at
# This is to to take the snaps / backups
#
# v1.0 Roger Sims 12 OCt : First release
# Logs to stdout for ansible and to local logs
#
# v2.0 Chris Fumai April 2022: Removed logic for dracut dm-snapshot
#


logdir=/var/log
shortdate=`date +%d%m%y`
update_log=$logdir/"OS_update_log_"$shortdate".out"
timestamp() {
  date +"%T:%d%m%y" # use with $(timestamp)
}

echo "################################################" >> $update_log 2>&1
echo "INFO : Starting 2_snapscript.sh at $(timestamp)" >> $update_log 2>&1
echo "INFO : Starting 2_snapscript.sh at $(timestamp)" 
echo "" >> $update_log 2>&1

# Added check logic for us to bomb out early on purpose if someone previously edited dracut.conf
# Seems very unlikely but never say never
#dracut_detect=`grep add_drivers /etc/dracut.conf | grep -v "#" | grep -v "dm-snapshot" | wc -l` >> $update_log 2>&1
#if [ "$dracut_detect" -ge 1 ]
#then
#  echo "ERROR : $(timestamp) /etc/dracut.conf has manually changed add_driver definitions, exiting" >> $update_log 2>&1
#  echo "ERROR : $(timestamp) /etc/dracut.conf has manually changed add_driver definitions, exiting" 
#  exit 1
#fi

# commented out lines 38-72 by cf - 04082022

#echo "INFO : $(timestamp) Starting dracut work to include dm-snapshot" >> $update_log 2>&1
#echo "INFO : $(timestamp) Starting dracut work to include dm-snapshot"


# NOTE to consider a re-write to inspect the running kernel's initird with lsinitrd to see if the dm-snapshot is contained
#dracut_detect_snap=`grep add_drivers /etc/dracut.conf | grep -v "#" | grep "dm-snapshot" | wc -l`  >> $update_log 2>&1
#if [ $dracut_detect_snap -le 0 ]
#then
#  echo "INFO : $(timestamp) making dracut edits to cope with snap lvm reboots" >> $update_log 2>&1
#  echo "INFO : $(timestamp) making dracut edits to cope with snap lvm reboots"
#  /bin/cp /etc/dracut.conf /etc/dracut.conf.$(timestamp)
#  echo "#Adding custom add_drivers" >> /etc/dracut.conf
#  echo "add_drivers+=\"dm-snapshot\"" >> /etc/dracut.conf
#  echo "INFO : $(timestamp) Rebuilding the initramfs via dracut to include dm-snapshot to safely boot with snaps" >> $update_log 2>&1
#  echo "INFO : $(timestamp) Rebuilding the initramfs via dracut to include dm-snapshot to safely boot with snaps"
#
#  # Taking a simple backup of the initrd to one side, just in case it was somehow customised
#  mkdir -p /var/backup_initramfs/boot/
#  for i in `ls -1 /boot/init*x86_64.img`
#  do
#    cp $i /var/backup_initramfs/$i.$(timestamp)
#  done
#  
#  /bin/dracut -f >> $update_log 2>&1
#  
#  if [ $? -ne 0 ]
#  then
#    echo "ERROR : $(timestamp) Please Check the OS logs to confirm what went wrong with dracut -f to rebuild the existing kernel initramfs" >> $update_log 2>&1
#    echo "ERROR : $(timestamp) Please Check the OS logs to confirm what went wrong with dracut -f to rebuild the existing kernel initramfs"
#    exit 1
#  else
#    echo "INFO : $(timestamp) dracut rebuilt the initramfs ok" >> $update_log 2>&1
#    echo "INFO : $(timestamp) dracut rebuilt the initramfs ok"
#  fi
# fi

# Make sure we have a root vg then continue with backups of boot,  or exit at the base of this BIG if
# Exit out at any point from failure with a unique log to file and ansible via std out
if [ -d "/dev/root_vg" ]
then
  mkdir -p /var/backup >> $update_log 2>&1
  if [ -d "/var/backup/boot" ]
  then
    echo "INFO : $(timestamp) Moving /var/backup/boot to /var/backup/boot.date" >> $update_log 2>&1
    mv /var/backup/boot /var/backup/boot.$(timestamp)
    echo "INFO : $(timestamp) Taking a backup of /boot to /var/backup/boot" >> $update_log 2>&1
    cp -r /boot /var/backup >> $update_log 2>&1
    if [ $? -ne 0 ]
    then
      echo "ERROR : $(timestamp) Backup of /boot has a non-zero exit code, exiting...." >> $update_log 2>&1
      echo "ERROR : $(timestamp) Backup of /boot has a non-zero exit code, exiting...."
      exit 1
    fi
  else
    echo "INFO : $(timestamp) Taking a backup of /boot to /var/backup/boot" >> $update_log 2>&1
    echo "INFO : $(timestamp) Taking a backup of /boot to /var/backup/boot"
    cp -r /boot /var/backup >> $update_log 2>&1
    if [ $? -ne 0 ]
    then
      echo "ERROR : $(timestamp) Backup of /boot has a non-zero exit code, exiting...." >> $update_log 2>&1
      echo "ERROR : $(timestamp) Backup of /boot has a non-zero exit code, exiting...."
      exit 1
    fi
  fi
  #
  # Now take the actual LV snaps, assuming only root and var but will snap others if found 
  #
  echo  "INFO : $(timestamp) Printing all LVS seen to the log" >> $update_log 2>&1
  lvs >> $update_log 2>&1
  lvdisplay >> $update_log 2>&1
  for i in `ls -1 /dev/root_vg | egrep "root|var|opt|usr"`
    do echo "INFO : $(timestamp) $i Snap being taken at $(timestamp)" >> $update_log 2>&1
    echo "" >> $update_log
    #lvdisplay >> $update_log 2>&1
    #echo "" >> $update_log
  #lvcreate -s -L 8G -n "$i"snap /dev/root_vg/$i >> $update_log 2>&1
    lvcreate -s -L 15G -n "$i"snap root_vg/$i >> $update_log 2>&1
    if [ $? -ne 0 ]
    then
      echo "ERROR : $(timestamp) LVM snap creation non-zero exit code, exiting...." >> $update_log 2>&1
      echo "ERROR : $(timestamp) LVM snap creation non-zero exit code, exiting...."
      exit 1
    fi
    sleep 5
  done
else
  echo "ERROR : $(timestamp) lvm root_vg not found, cannot take snaps, exiting...."
  echo "ERROR : $(timestamp) lvm root_vg not found, cannot take snaps, exiting...." >> $update_log 2>&1
  exit 1
fi

echo "" >> $update_log 2>&1
echo "INFO : $(timestamp) Finished 2_snapscript.sh"
echo "INFO : $(timestamp) Finished 2_snapscript.sh" >> $update_log 2>&1
echo "################################################" >> $update_log 2>&1
