#!/bin/bash
#
# Removal of OpenOnload content from machines in question
# Will need expansion to remove other content
#
# v1.0 Roger Sims 12 OCt : First release
# Logs to stdout for ansible and to local logs

# v2.0 Chris Fumai 2/22: Second release for RHEL8

logdir=/var/log
shortdate=`date +%d%m%y`
update_log=$logdir/"OS_update_log_"$shortdate".out"
timestamp() {
  date +"%T:%d%m%y" # use with $(timestamp)
}

echo "################################################" >> $update_log 2>&1
echo "INFO : $(timestamp) Starting 6_post_update_work.sh" >> $update_log 2>&1
echo "INFO : $(timestamp) Starting 6_post_update_work.sh"

echo "Disabling CSfirstboot service and removing any stale /.firstbooted file" >> $update_log 2>&1
echo "Disabling CSfirstboot service and removing any stale /.firstbooted file"
/sbin/chkconfig CSfirstboot off
if [ -f /.firstbooted ]
then
   echo "Removing /.firstbooted file" >> $update_log 2>&1
   echo "Removing /.firstbooted file"
   rm /.firstbooted
fi

echo "INFO : $(timestamp) Noting cards seen to local logs" >> $update_log 2>&1
/sbin/lspci | grep Ethernet >> $update_log 2>&1
  
echo "INFO : $(timestamp) Starting install of Onload from ISV repo's" >> $update_log 2>&1
echo "INFO : $(timestamp) Starting install of Onload from ISV repo's" 

# ensure onload is removed
/bin/rpm -qa | grep onload  >> $update_log 2>&1
onload_detect=`/bin/rpm -qa | grep -i onload* | wc -l` >> $update_log 2>&1
if [ "$onload_detect" -ge 1 ]
then
  echo "INFO : $(timestamp) Found onload installed, removing"  >> $update_log
  echo "INFO : $(timestamp) Found onload installed, removing"

  yum -y remove onload* >> $update_log 2>&1
fi

# Need alternate approach to match latest kernel installed which we are not yet booted from. Uname -r returns the old kernel we're booted from
# NOTE : Curently handling patching to a fixed kernel release so sfutils / onload and dracut command would need to change

# RHEL8

yum -y --disablerepo=* --enablerepo=Default_Organization_ISV_Content_RHEL_8_4_ISV_content install onload-kmod-4.18.0-305.25.1.el8_4-7.1.2.141-1.el8.x86_64 onload-7.1.2.141-1.el8.x86_64 onload-sfcirqaffinity-7.1.2.141-1.el8.x86_64 >> $update_log 2>&1

if [ $? -ne 0 ] 
then 
  echo "ERROR : $(timestamp) Non-zero exit code on YUM install of onload, check logs / for prescence of drivers before rebooting.." >> $update_log 2>&1
  echo "ERROR : $(timestamp) Non-zero exit code on YUM install of onload, check logs / for prescence of drivers before rebooting.."
  exit 1
else
  echo "INFO : $(timestamp) Onload related rpm's installed OK"  >> $update_log 2>&1
  echo "INFO : $(timestamp) Onload related rpm's installed OK"
fi

# Now lets rebuild the initrd again to ensure it has built for our kernel :
rpm -qa | grep "kernel-4.18.0-305.25.1.el8_4.x86_64"
if [ $? -eq 0 ]
then
  echo "INFO : $(timestamp) Performing pre-reboot dracut initramfs generation to cope with Onload rpm postinstall logic" >> $update_log 2>&1
  echo "INFO : $(timestamp) Performing pre-reboot dracut initramfs generation to cope with Onload rpm postinstall logic"
  /bin/dracut -f "initramfs-4.18.0-305.25.1.el8_4.x86_64.img" "4.18.0-305.25.1.el8_4.x86_64" >> $update_log 2>&1
  if [ $? -ne 0 ]
  then
    echo "ERROR : $(timestamp) Check the OS logs to confirm what went wrong with dracut" >> $update_log 2>&1
    echo "ERROR : $(timestamp) Check the OS logs to confirm what went wrong with dracut"
    exit 1
  else
    echo "INFO : $(timestamp) dracut rebuilt the initrd ok" >> $update_log 2>&1
    echo "INFO : $(timestamp) dracut rebuilt the initrd ok"
  fi
else
  echo "ERROR : $(timestamp) Confirm that kernel 4.18.0-305.25.1.el8-7.1.2.141-1.el8.x86_64 installed as expected" >> $update_log 2>&1
  echo "ERROR : $(timestamp) Confirm that kernel 4.18.0-305.25.1.el8-7.1.2.141-1.el8.x86_64 installed as expected"
  exit 1
fi

# Now remove and reinstall the latest sfutils as some have old sfutils and some have current so cannot easily upgrade or install without a wrapper
# Have broken out to seperate yum invocation in case our LLREPO ever breaks so the above sfc drivers should install from the katello repo.
echo "INFO : $(timestamp) Starting sfutils / firmware updates" >> $update_log 2>&1
echo "INFO : $(timestamp) Starting sfutils / firmware updates" 
yum -y --disablerepo=* remove sfutils >> $update_log 2>&1
yum -y --disablerepo=* --enablerepo=llrepo install sfutils >> $update_log 2>&1
if [ $? -ne 0 ]
then
  echo "ERROR : $(timestamp) Confirm that sfutils installed ok from the llrepo" >> $update_log 2>&1
  echo "ERROR : $(timestamp) Confirm that sfutils installed ok from the llrepo"
  exit 1
else
  echo "INFO : $(timestamp) sfutils installed OK" >> $update_log 2>&1
  echo "INFO : $(timestamp) sfutils installed OK"
  echo "INFO : $(timestamp) Starting sfupdate for firmware on SF cards only" >> $update_log 2>&1
  echo "INFO : $(timestamp) Starting sfupdate for firmware on SF cards only"
  sfupdate --write -y >> $update_log 2>&1
  if [ $? -ne 0 ]
  then
    echo "ERROR : $(timestamp) Non-zero exit from sfupdate, Check /var/log/OS_update_log for what happened inside the firmware update" >> $update_log 2>&1
    echo "ERROR : $(timestamp) Non-zero exit from sfupdate, Check /var/log/OS_update_log for what happened inside the firmware update"
  else
    echo "INFO : $(timestamp) sfupdate returned exit zero, continuing" >> $update_log 2>&1
    echo "INFO : $(timestamp) sfupdate returned exit zero, continuing" 
  fi
fi

DirectAudit=`/bin/rpm -qa | grep CentrifyDA | wc -l` >> $update_log 2>&1
if [ "$DirectAudit" -ge 1 ]
then
  echo "INFO : $(timestamp) Found DirectAudit installed, enabling post patching"  >> $update_log
  echo "INFO : $(timestamp) Found DirectAudit installed, enabling post patching"
  echo "INFO : $(timestamp) Enabling and Starting centrifyda daemon" >> $update_log
  echo "INFO : $(timestamp) Enabling and Starting centrifyda daemon"
  systemctl enable centrifyda >> $update_log 2>&1
  systemctl start centrifyda >> $update_log 2>&1
fi

# puppet enable/disable check
puppetlock_file=/opt/puppetlabs/puppet/cache/state/agent_disabled.lock
if [[ -f $puppetlock_file ]]; then
   echo "INFO : $(timestamp) $puppetlock_file found - enabling puppet agent" >> $update_log 2>&1
   echo "INFO : $(timestamp) $puppetlock_file found - enabling puppet agent"
   touch /var/backup/puppet.agent_disabled.lock
   puppet agent --enable >> $update_log 2>&1
fi

# Leaving in as a blank format as I believe I will need to do something with puppet once upgraded, likely /etc/init.d/functions
echo "INFO : $(timestamp) Invoking pupe to correctly set services, NTP and Shell functions per puppet definitions" >> $update_log 2>&1
echo "INFO : $(timestamp) Invoking pupe to correctly set services, NTP and Shell functions per puppet definitions" 
# NOTE: path deliberatley left undeclared as 7.2 & 7.5 have differing paths and is part of roots path on either
#puppet agent -tov --tags Services,Ntp,Shellrc,Centrify,Remove_nproc_limit >> $update_log 2>&1

# added proper kernel tags prior to reboot process to handle nic card renaming 
puppet agent -tov --tags Hardware,Bootconfig,Interfaces,Services,Ntp,Shellrc,Centrify,Remove_nproc_limit >> $update_log 2>&1

echo "INFO : $(timestamp) Finshed 6_post_update_work.sh"
echo "INFO : $(timestamp) Finshed 6_post_update_work.sh" >> $update_log 2>&1
echo "################################################" >> $update_log 2>&1
