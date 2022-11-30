#!/bin/bash
#
# Removal of OpenOnload content from machines in question
# Will need expansion to remove other content
#
# v1.0 Roger Sims 12 OCt : First release
# Logs to stdout for ansible and to local logs
# Amended to make RHEL 7 specific and to remove onload on RHEL 7
#
# v2.0 Chris Fumai 2/22: Second Releaes
# Amended to make RHEL 8 specific

logdir=/var/log
shortdate=`date +%d%m%y`
update_log=$logdir/"OS_update_log_"$shortdate".out"
timestamp() {
  date +"%T:%d%m%y" # use with $(timestamp)
}

echo "################################################" >> $update_log 2>&1
echo "INFO : $(timestamp) Starting 4_preupdate_content_remove.sh." >> $update_log 
echo "INFO : $(timestamp) Starting 4_preupdate_content_remove.sh."
/bin/rpm -qa | grep onload  >> $update_log 2>&1
onload_detect=`/bin/rpm -qa | grep -i onload* | wc -l` >> $update_log 2>&1
if [ "$onload_detect" -ge 1 ]
then

  echo "INFO : $(timestamp) Found onload installed, removing"  >> $update_log 
  echo "INFO : $(timestamp) Found onload installed, removing"

  yum -y remove onload* >> $update_log 2>&1

  onload_detect_afteryum=`/bin/rpm -qa | grep -i onload* | wc -l`

  if [ "$onload_detect_afteryum" -ge 1 ]
  then
    echo "ERROR : $(timestamp) : Found onload rpm's still present after a loop of removal, exiting..." >> $update_log 2>&1
    echo "ERROR : $(timestamp) : Found onload rpm's still present after a loop of removal, exiting..."
    exit 1
  fi
else
  echo "INFO : $(timestamp) No onload detected, continuing....." >> $update_log 2>&1
  echo "INFO : $(timestamp) No onload detected, continuing....." 
  echo "" >> $update_log 2>&1
fi

DirectAudit=`/bin/rpm -qa | grep CentrifyDA | wc -l` >> $update_log 2>&1
if [ "$DirectAudit" -ge 1 ]
then
  echo "INFO : $(timestamp) Found DirectAudit installed, disabling before continuation"  >> $update_log
  echo "INFO : $(timestamp) Found DirectAudit installed, disabling before continuation"
  /usr/bin/dainfo >>  $update_log
  echo "INFO : $(timestamp) Stopping centrifyda daemon" >> $update_log
  echo "INFO : $(timestamp) Stopping centrifyda daemon"
  systemctl stop centrifyda >> $update_log
  echo "INFO : $(timestamp) Disabling shell under DA control for the duration of patching" >> $update_log
  echo "INFO : $(timestamp) Disabling shell under DA control for the duration of patching"
  /usr/sbin/dacontrol -d -a  >> $update_log 2>&1
  if [ $? -ne 0 ]
  then
    echo "ERROR : $(timestamp) dacontrol -d -a has a non-zero exit code, exiting as Direct Audit may still be enabled
." >> $update_log 2>&1
    echo "ERROR : $(timestamp) dacontrol -d -a has a non-zero exit code, exiting as Direct Audit may still be enabled
."
    /usr/bin/dainfo >>  $update_log 2>&1
    /usr/bin/dainfo
    exit 1
  fi
  echo "INFO : $(timestamp) Printing Direct Audit status after disable"  >> $update_log
  echo "INFO : $(timestamp) Printing Direct Audit status after disable"
  /usr/bin/dainfo >>  $update_log 2>&1
  /usr/bin/dainfo
else
  echo "INFO : $(timestamp) No DirectAudit detected, continuing....." >> $update_log 2>&1
  echo "INFO : $(timestamp) No DirectAudit detected, continuing....."
  echo "" >> $update_log 2>&1
fi

# ensure onload is removed
/bin/rpm -qa | grep onload  >> $update_log 2>&1
onload_detect=`/bin/rpm -qa | grep -i onload* | wc -l` >> $update_log 2>&1
if [ "$onload_detect" -ge 1 ]
then

  echo "INFO : $(timestamp) Found onload installed, removing"  >> $update_log 
  echo "INFO : $(timestamp) Found onload installed, removing"

  yum -y remove onload* >> $update_log 2>&1

fi

echo ""  >> $update_log 2>&1
echo "INFO : $(timestamp) Completion of 4_preupdate_content_remove.sh" >> $update_log 2>&1
echo "INFO : $(timestamp) Completion of 4_preupdate_content_remove.sh"
echo "################################################" >> $update_log 2>&1

