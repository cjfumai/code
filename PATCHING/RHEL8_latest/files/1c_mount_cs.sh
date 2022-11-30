#!/bin/sh
# 
# v1.0 Chris Fumai: mount /cs prior to resize
#

logdir=/var/log
shortdate=`date +%d%m%y`
update_log=$logdir/"OS_update_log_"$shortdate".out"
timestamp() {
  date +"%T:%d%m%y" # use with $(timestamp)
}

file=/etc/fstab
lv=root_vg-cs
mount=/cs

echo "################################################" >> $update_log 2>&1
echo "INFO : Starting 1c_mount_cs.sh at $(timestamp)" >> $update_log 2>&1
echo "INFO : Starting 1c_mount_cs.sh at $(timestamp)"

grep $lv $file | grep -i "$mount. "
if [ $? -eq 0 ]; then
   sed -e '/^#\/dev\/mapper\/root_vg-cs.*\/cs. /s/^#//' -i $file
   mount /cs
fi

echo "INFO: starting lldpd" >> $update_log 2>&1
echo "INFO: starting lldpd"
systemctl start lldpd

echo "" >> $update_log 2>&1
echo "INFO : Finished 1c_mount_cs.sh at $(timestamp)" >> $update_log 2>&1
echo "INFO : Finished 1c_mount_cs.sh at $(timestamp)"
echo "################################################" >> $update_log 2>&1
