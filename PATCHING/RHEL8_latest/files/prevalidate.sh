#!/bin/bash -x
#
# v1.0 Chris Fumai 4 2022: make available to ops to pre-check a machine before update
# v1.1 Chris Fumai: added checks for duplicate rpms
# v1.2 Chris Fumai: added better logging output and file copy from remote to local logs dir

logdir=/var/log
shortdate=`date +%d%m%y`
update_log=$logdir/"OS_prevalidate_log_"$shortdate".out"
timestamp() {
  date +"%T:%d%m%y" # use with $(timestamp)
}

desired_release=8.4

echo "##########################################################################################" >> $update_log 2>&1
echo "INFO : Starting prevalidate.sh at $(timestamp)" >> $update_log 2>&1
echo "INFO : Starting prevalidate.sh at $(timestamp)"
echo "" >> $update_log 2>&1

# exit if host is already at desired release
current_release=`facter  operatingsystemrelease`
if [ $current_release = $desired_release ]
then
   echo "INFO: host is already at RHEL $desired_release exiting" >> $update_log 2>&1
   echo "`hostname` is already running RHEL $desired_release update not required"
   os_already_fail=1
fi

# check if grubenv is munged
if [ -s /boot/grub2/grubenv ]; then
   echo "INFO: /boot/grub2/grubenv is OK" >> $update_log 2>&1
   echo "INFO: /boot/grub2/grubenv is OK"
echo "" >> $update_log 2>&1
else
   echo "ERROR: /boot/grub2/grubenv is zero length" >> $update_log 2>&1
   echo "ERROR: /boot/grub2/grubenv is zero length"
   echo "INFO:  fixing /boot/grub2/grubenv file" >> $update_log 2>&1
   echo "INFO:  fixing /boot/grub2/grubenv file"
   echo "INFO:  moving /boot/grub2/grubenv to /tmp" >> $update_log 2>&1
   echo "INFO:  moving /boot/grub2/grubenv to /tmp"
   mv /boot/grub2/grubenv /tmp/
   grub2-mkconfig -o /boot/grub2/grub.cfg >> $update_log 2>&1
   grubby --info=ALL | egrep -i '(environment|block)' >> $update_log 2>&1
   echo "" >> $update_log 2>&1
   grub_env_fail=1
fi

grubby --info=ALL | egrep -i '(environment|block)'
if [ $? = 1 ]; then
   echo "INFO: grubby info is OK" >> $update_log 2>&1
   echo "INFO: grubby info is OK"
echo "" >> $update_log 2>&1
else
   echo "ERROR: grub / grubenv config files need review" >> $update_log 2>&1
   echo "ERROR: grub / grubenv config files need review" >> $update_log 2>&1
   echo "" >> $update_log 2>&1
   grubby_config_fail=1 
fi

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
  echo "" >> $update_log 2>&1
fi

echo "INFO : $(timestamp) Printing state of all LVM vols seen " >> $update_log 2>&1
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
fi

vg_free=`vgs -o vg_free --noheadings --units b  --nosuffix root_vg` >> $update_log 2>&1
vgs -o vg_free --noheadings --units b  --nosuffix root_vg >> $update_log 2>&1
if [ "$vg_free" -le 33285996544 ]
  then
    echo "ERROR : $(timestamp) root_vg has less than 31G free"  >> $update_log 2>&1
    echo "ERROR : $(timestamp) root_vg has less than 31G free"
    vg_free_fail=1
  else
    echo "INFO : $(timestamp) root_vg free space OK" >> $update_log 2>&1
    echo "" >> $update_log 2>&1
fi

echo "INFO : $(timestamp) Starting rpm checks" >> $update_log 2>&1
rpms_list=`rpm -qa | egrep -i "falcon-store|VRTSvcs|SYMCvcs|VRTSvxvm|SYMCvxvm|VRTSvxfs|SYMCvxfs" | wc -l`
if [ $rpms_list -eq 0 ]
then
  echo "INFO : $(timestamp) No problematic RPM's found OK " >> $update_log 2>&1
  echo "" >> $update_log 2>&1
else
  echo "ERROR : $(timestamp) WARNING, problematic RPM's found manual intervention needed" >> $update_log 2>&1
  echo "ERROR : $(timestamp) WARNING, problematic RPM's found manual intervention needed"
  rpm -qa | egrep -i "falcon-store|VRTSvcs|SYMCvcs|VRTSvxvm|SYMCvxvm|VRTSvxfs|SYMCvxfs"  >> $update_log 2>&1
  rpm -qa | egrep -i "falcon-store|VRTSvcs|SYMCvcs|VRTSvxvm|SYMCvxvm|VRTSvxfs|SYMCvxfs"
  rpms_list_fail=1
fi

echo "INFO : $(timestamp) Starting dracut checks" >> $update_log 2>&1
dracut_detect=`grep add_drivers /etc/dracut.conf | grep -v "#" | grep -v "dm-snapshot" | wc -l` >> $update_log 2>&1
grep add_drivers /etc/dracut.conf | grep -v "#"  >> $update_log 2>&1
if [ "$dracut_detect" -ge 1 ]
then
  echo "ERROR : $(timestamp) /etc/dracut.conf has manually changed add_driver definitions exiting" >> $update_log 2>&1
  echo "ERROR : $(timestamp) /etc/dracut.conf has manually changed add_driver definitions exiting"
  dracut_detect_fail=1
else
  echo "INFO : $(timestamp) dracut checks have passed OK"  >> $update_log 2>&1
  echo "" >> $update_log 2>&1
fi

if [[ $cs_percent_free -gt 85 ]]; then
   echo "cs is over 90% used"
else
   echo "/cs is less then 85 percent OK" >> $update_log 2>&1
   echo "/cs is less then 85 percent OK"
fi

# puppet enable/disable check
puppetlock_file=/opt/puppetlabs/puppet/cache/state/agent_disabled.lock
if [[ -f $puppetlock_file ]]; then
   echo "ERROR : $(timestamp) $puppetlock_file found - puppet is disabled on this host" >> $update_log 2>&1 
   echo "ERROR : $(timestamp) $puppetlock_file found - puppet is disabled on this host"
   puppet_check_fail=1
fi

# check if puppet removed from crontab
crontab -l | grep -i puppet | grep -i agent  | grep -v "^#" >> $update_log 2>&1
if [[ $? -ne 0 ]]; then
   echo "ERROR : $(timestamp) puppet disabled in cron" >> $update_log 2>&1 
   echo "ERROR : $(timestamp) puppet disabled in cron"
fi


echo "INFO : $(timestamp) Starting duplicate rpms check" >> $update_log 2>&1
yum_check_file=/tmp/yumcheck
yum check > $yum_check_file 2>&1
grep -i duplicate $yum_check_file >> $update_log 2>&1
if [ $? -eq 0 ]; then
   echo "" >> $update_log 2>&1
   echo "ERROR : $(timestamp) duplicate rpms found on this host. fix/check these duplication rpms before upgrading" >> $update_log 2>&1
   echo "" >> $update_log 2>&1
   echo "`grep -i duplicate $yum_check_file`" >> $update_log 2>&1
   yum_check_fail=1 
fi

# Now test for prescence of the fail variables and exit 1 if found

if [ ! -z "$bootspace_fail" ] || [ ! -z "$snapdetect_fail" ] || [ ! -z "$vg_free_fail" ] || [ ! -z "$rpms_list_fail" ] || [ ! -z "$dracut_detect_fail" ] || [ ! -z "$yum_check_fail" ]] || [[ ! -z "$puppet_check_fail" ]] || [[ ! -z "$os_already_fail" ]] || [[ ! -z "$grub_env_fail" ]] || [[ ! -z "$grubby_config_fail" ]]
then
   echo "" >> $update_log 2>&1
   echo "ERROR : $(timestamp) check failed check logfile in /var/log" >> $update_log 2>&1
   echo "ERROR : $(timestamp) check failed check logfile in /var/log" 
else
   echo "INFO : $(timestamp) No failures found from pre-validation, upgrade can proceed" >> $update_log 2>&1
   echo "INFO : $(timestamp) No failures found from pre-validation, upgrade can proceed"
fi

echo "" >> $update_log 2>&1
echo "INFO : Finished prevalidate.sh at $(timestamp)" >> $update_log 2>&1
echo "INFO : Finished prevalidate.sh at $(timestamp)"
echo "##########################################################################################" >> $update_log 2>&1
