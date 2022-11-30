#!/bin/bash
#
# v1.0 Chris Fumai 4/22: moved this check to a script instead of inside playbook

logdir=/var/log
shortdate=`date +%d%m%y`
update_log=$logdir/"OS_update_log_"$shortdate".out"
timestamp() {
  date +"%T:%d%m%y" # use with $(timestamp)
}

echo "################################################" >> $update_log 2>&1
echo "INFO : $(timestamp) Starting 6a_check_sane_reboot" >> $update_log 2>&1
echo "INFO : $(timestamp) Starting 6a_check_sane_reboot"

LAST_KERNEL=`rpm -q --last kernel | awk 'NR==1{sub(/kernel-/,""); print $1}'`
CURRENT_KERNEL=$(uname -r)

if [ $LAST_KERNEL != $CURRENT_KERNEL ]
then echo "reboot"
else
   echo "no"
fi

echo "INFO : $(timestamp) Finshed 6a_check_sane_reboot" >> $update_log 2>&1
echo "################################################" >> $update_log 2>&1
