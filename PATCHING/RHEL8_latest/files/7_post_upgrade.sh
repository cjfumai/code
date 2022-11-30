#!/bin/bash
#
# Removal of OpenOnload content from machines in question
# Will need expansion to remove other content
#
# v1.0 Roger Sims 12 OCt : First release
# Logs to stdout for ansible and to local logs
#
# v2.0 Chris Fumai 2/22: Second release updated for RHEL8.1 to RHEL 8.4

logdir=/var/log
shortdate=`date +%d%m%y`
update_log=$logdir/"OS_update_log_"$shortdate".out"
timestamp() {
  date +"%T:%d%m%y" # use with $(timestamp)
}

echo "################################################" >> $update_log 2>&1

echo "INFO : $(timestamp) Starting post-reboot puppet actions to set new banner and repo settings" >> $update_log 2>&1
echo "INFO : $(timestamp) Starting post-reboot puppet actions to set new banner and repo settings"

# Note, these are cosmetic changes that do not change core os behaviour so exec'ing after reboot
# NOTE : Path undeclared on purpose as differs on 7.2 / 7.9 and is in roots path
puppet agent -tov --tags Repos,Banners,Services >> $update_log 2>&1
vers_count=`grep -w "8.4" /etc/motd | wc -l`
if [ $vers_count = 0 ]
then
  echo "ERROR : $(timestamp) Redhat 8.4 not found in banner, confirm that puppet agent -tov --tags Repos,Banners completed sucessfully" >> $update_log 2>&1
  echo "ERROR : $(timestamp) Redhat 8.4 not found in banner, confirm that puppet agent -tov --tags Repos,Banners completed sucessfully"
  exit 1
else
  echo "INFO : $(timestamp) post reboot puppet agent run sucessfully to set new banner and repo settings" >> $update_log 2>&1
  echo "INFO : $(timestamp) post reboot puppet agent run sucessfully to set new banner and repo settings"
fi

if [ -f /var/backup/puppet.agent_disabled.lock ]; then
   echo "INFO : $(timestamp) /var/backup/puppet.agent_disabled.lock found - disabling puppet agent post update" >> $update_log 2>&1
   puppet agent --disable "disable puppet agent post update" >> $update_log 2>&1
   puppet agent --disable "disable puppet agent post update"
fi
