#!/bin/bash
#
# Test for the release version set
# Test for the numnber of repo's
# Press on when we are happy or exit 1
#
# v1.0 Roger Sims 12 OCt : First release
# Logs to stdout for ansible and to local logs
#
# v2.0 Chris Fumai 2/22: Second release for RHEL 8 support


logdir=/var/log
shortdate=`date +%d%m%y`
update_log=$logdir/"OS_update_log_"$shortdate".out"
timestamp() {
  date +"%T:%d%m%y" # use with $(timestamp)
}

echo "################################################" >> $update_log 2>&1
echo "INFO : $(timestamp) Starting subscribe_validate script." >> $update_log 2>&1
echo "INFO : $(timestamp) Starting subscribe_validate script."

if [ -f /usr/sbin/subscription-manager ]
then
  #pre_subver=`/usr/sbin/subscription-manager release` >> $update_log 2>&1
  echo "INFO : $(timestamp) Removing old subscriptions." >> $update_log 2>&1
  echo "INFO : $(timestamp) Removing old subscriptions."
  /usr/sbin/subscription-manager clean >> $update_log 2>&1
else
  echo "ERROR : $(timestamp) Did not find subscription-managers, exiting...." >> $update_log 2>&1
  echo "ERROR : $(timestamp) Did not find subscription-managers, exiting...." 
  exit 1
fi

#if [ "$pre_subver" != "Release: 8Server" ]
#then
  echo "INFO : $(timestamp) Subscription-manager registration starting." >> $update_log 2>&1
  echo "INFO : $(timestamp) Subscription-manager registration starting."
  /usr/sbin/subscription-manager register --org="Default_Organization" --activationkey="RHEL 8.4" --force >> $update_log 2>&1

# attach ISV content pool id 
  /usr/sbin/subscription-manager attach --pool=268d33997495f1120174a0b3c8fc00d2 >> $update_log >> $update_log 2>&1

  if [ $? -ne 0 ]
  then
    echo "ERROR : $(timestamp) Subscription manager registration may have failed, check subscription-manager status" >> $update_log 2>&1
    echo "ERROR : $(timestamp) Subscription manager registration may have failed, check subscription-manager status"
    exit 1
  else
    subscription-manager release --set=8.4
    if [ $? -ne 0 ]
    then
      echo "ERROR : $(timestamp) Subscription manager release definition may have failed, check subscription-manager status" >> $update_log 2>&1
      echo "ERROR : $(timestamp) Subscription manager release definition may have failed, check subscription-manager status"
      exit 1
    fi
  fi
#else
  # Can we test subscription manager status as to registration ?
#  echo "INFO : $(timestamp) Subscription manager is already registered as RHEL 8.4 Non Prod"  >> $update_log 2>&1
#  echo "INFO : $(timestamp) Subscription manager is already registered as RHEL 8.4 Non Prod"
#fi

echo "" >> $update_log 2>&1
echo "INFO : $(timestamp) Finished subscribe_validate script." >> $update_log 2>&1
echo "INFO : $(timestamp) Finished subscribe_validate script."
echo "################################################" >> $update_log 2>&1
