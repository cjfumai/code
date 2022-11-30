#!/bin/sh
# 
# v1.0 Chris Fumai: katello certs install
#

logdir=/var/log
shortdate=`date +%d%m%y`
update_log=$logdir/"OS_update_log_"$shortdate".out"
timestamp() {
  date +"%T:%d%m%y" # use with $(timestamp)
}

# katello info
katello_master=vsol06i-0006.eu.hedani.net
katello_rpm=katello-ca-consumer-latest.noarch.rpm

echo "################################################" >> $update_log 2>&1
echo "INFO : Starting 2a_katello_certs.sh at $(timestamp)" >> $update_log 2>&1
echo "INFO : Starting 2a_katello_certs.sh"

cd /tmp/
curl --insecure --output $katello_rpm https://$katello_master/pub/katello-ca-consumer-latest.noarch.rpm
yum -y localinstall $katello_rpm >> $update_log 2>&1

rpm -qa katello-ca-consumer-$katello_master

if [ $? -eq 0 ]; then
   echo "INFO: $katello_rpm installed successfully" >> $update_log 2>&1
   echo "INFO: $katello_rpm installed successfully"
else 
   echo "ERROR: $katello_rpm not installed exiting" >> $update_log 2>&1
   echo "ERROR: $katello_rpm not installed exiting"
   exit 1
fi

echo "" >> $update_log 2>&1
echo "INFO : Finished 2a_katello_certs.sh at $(timestamp)" >> $update_log 2>&1
echo "INFO : Finished 2a_katello_certs.sh at $(timestamp)"
echo "################################################" >> $update_log 2>&1
