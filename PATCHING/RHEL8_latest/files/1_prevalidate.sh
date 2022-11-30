#!/bin/bash
# 
# Scripted attempt to seek out issues and exit if we have problems.
# Will exit 1 which should prevent the rest of the ansible playbook continuing
# v1.0 Roger Sims 12 OCt : First release
# Logs to stdout for ansible and to local logs


logdir=/var/log
shortdate=`date +%d%m%y`
update_log=$logdir/"OS_update_log_"$shortdate".out"
timestamp() {
  date +"%T:%d%m%y" # use with $(timestamp)
}

echo "################################################" >> $update_log 2>&1
echo "INFO : Starting 1_prevalidate.sh at $(timestamp)" >> $update_log 2>&1
echo "INFO : Starting 1_prevalidate.sh at $(timestamp)"

echo "INFO : $(timestamp) Starting bootspace checks" >> $update_log 2>&1
bootspace=`df -k /boot | grep boot | awk '{print $4}'` >> $update_log 2>&1
df -k /boot | grep boot >> $update_log 2>&1
echo "" >> $update_log 2>&1
if [ "$bootspace" -le 100000 ]
then
  echo "ERROR : $(timestamp) Insufficient space in /boot, only $bootspace, hence attention on /boot usage needed"
  echo "ERROR : $(timestamp) Insufficient space in /boot, only $bootspace, hence attention on /boot usage needed" >> $update_log 2>&1
  bootspace_fail=1
else
  echo "INFO : $(timestamp) Found $bootspace kilobytes of space in /boot, continuing....." >> $update_log 2>&1
#  echo "INFO : $(timestamp) Found $bootspace kilobytes of space in /boot, continuing....."
  echo "" >> $update_log 2>&1
fi

echo "INFO : $(timestamp) Printing state of all LVM vols seen " >> $update_log 2>&1
#echo "INFO : $(timestamp) Printing state of all LVM vols seen " 
echo "" >> $update_log 2>&1
/sbin/lvs >> $update_log 2>&1
echo "" >> $update_log 2>&1

echo "INFO : $(timestamp) Starting snap checks" >> $update_log 2>&1
snapdetect=`/sbin/lvs root_vg -a -v | grep snap | wc -l` >> $update_log 2>&1
if [ "$snapdetect" -ge 1 ]
then
  echo "ERROR : $(timestamp) Found we already have root_vg snapshots, needs attention before OS update"  >> $update_log 2>&1
  echo "ERROR : $(timestamp) Found we already have root_vg snapshots, needs attention before OS update"
  snapdetect_fail=1
else
  echo "INFO : $(timestamp) No root snaps detected, continuing." >> $update_log 2>&1
  echo "" >> $update_log 2>&1
#  echo "INFO : $(timestamp) No root snaps detected, continuing."
fi
  # Note : current assumption is that root_vg snaps will need 31gb free
vg_free=`vgs -o vg_free --noheadings --units b  --nosuffix root_vg` >> $update_log 2>&1
vgs -o vg_free --noheadings --units b  --nosuffix root_vg >> $update_log 2>&1
if [ "$vg_free" -le 33285996544 ]
  then
    echo "ERROR : $(timestamp) root_vg has less than 31G free, needs attention before OS update"  >> $update_log 2>&1
    echo "ERROR : $(timestamp) root_vg has less than 31G free, needs attention before OS update"
    vg_free_fail=1
  else
    echo "INFO : $(timestamp) root_vg has at least 31G free, continuing." >> $update_log 2>&1
    echo "" >> $update_log 2>&1
#    echo "INFO : $(timestamp) root_vg has at least 31G free, continuing."
fi

echo "INFO : $(timestamp) Starting rpm checks" >> $update_log 2>&1
rpms_list=`rpm -qa | egrep -i "falcon-store|VRTSvcs|SYMCvcs|VRTSvxvm|SYMCvxvm|VRTSvxfs|SYMCvxfs" | wc -l`
if [ $rpms_list -eq 0 ]
then
  echo "INFO : $(timestamp) No problematic RPM's found, continuing" >> $update_log 2>&1
  echo "" >> $update_log 2>&1
else
  echo "ERROR : $(timestamp) WARNING, problematic RPM's found, manual intervention needed. Veritas or Falcon found" >> $update_log 2>&1
  echo "ERROR : $(timestamp) WARNING, problematic RPM's found, manual intervention needed. Veritas or Falcon found"
  rpm -qa | egrep -i "falcon-store|VRTSvcs|SYMCvcs|VRTSvxvm|SYMCvxvm|VRTSvxfs|SYMCvxfs"  >> $update_log 2>&1
  rpm -qa | egrep -i "falcon-store|VRTSvcs|SYMCvcs|VRTSvxvm|SYMCvxvm|VRTSvxfs|SYMCvxfs"
  rpms_list_fail=1
fi

echo "INFO : $(timestamp) Starting dracut checks" >> $update_log 2>&1
dracut_detect=`grep add_drivers /etc/dracut.conf | grep -v "#" | grep -v "dm-snapshot" | wc -l` >> $update_log 2>&1
grep add_drivers /etc/dracut.conf | grep -v "#"  >> $update_log 2>&1
if [ "$dracut_detect" -ge 1 ]
then
  echo "ERROR : $(timestamp) /etc/dracut.conf has manually changed add_driver definitions, exiting" >> $update_log 2>&1
  echo "ERROR : $(timestamp) /etc/dracut.conf has manually changed add_driver definitions, exiting"
  dracut_detect_fail=1
else
  echo "INFO : $(timestamp) dracut checks have passed OK, continuing"  >> $update_log 2>&1
  echo "" >> $update_log 2>&1
fi

# Now test for prescence of the fail variables and exit 1 if found
if [ ! -z "$bootspace_fail" ] || [ ! -z "$snapdetect_fail" ] || [ ! -z "$vg_free_fail" ] || [ ! -z "$rpms_list_fail" ] || [ ! -z "$dracut_detect_fail" ]
  then
    echo "ERROR : $(timestamp) WARNING, exiting as failure conditions found, please review logs in /var/log/OS_update_log*" >> $update_log 2>&1
    echo "ERROR : $(timestamp) WARNING, exiting as failure conditions found, please review logs in /var/log/OS_update_log*"
    exit 1
else
    echo "INFO : $(timestamp) No failures found from the check script, hence continuing" >> $update_log 2>&1
    echo "INFO : $(timestamp) No failures found from the check script, hence continuing"
fi

echo "" >> $update_log 2>&1
echo "INFO : Finished 1_prevalidate.sh at $(timestamp)" >> $update_log 2>&1
echo "INFO : Finished 1_prevalidate.sh at $(timestamp)"
echo "################################################" >> $update_log 2>&1

