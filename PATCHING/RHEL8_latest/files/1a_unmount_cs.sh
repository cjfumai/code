#!/bin/sh
# 
# v1.0 Chris Fumai: unmount /cs prior to resize
# v1.1 Chris Fumai: changed to check /cs, if /cs is not part of root_vg, do not unmount and continue update
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
echo "INFO : Starting 1a_unmount_cs.sh at $(timestamp)" >> $update_log 2>&1
echo "INFO : Starting 1a_unmount_cs.sh at $(timestamp)"

grep  "/cs " /etc/fstab | egrep -i '(ext4|xfs)'
if [ $? -ne 0 ]; then
   echo "/cs is not a separate FS review before updating this host"
   exit 1
else
   echo "/cs is mounted - continuing"
fi

cs_root_vg_check=`lvs |grep cs | grep root_vg`
if [ $cs_root_vg_check -ne 0 ]; then
   echo "/cs is a separate FS not in root_vg continuing" >> $update_log 2>&1
   echo "/cs is a separate FS not in root_vg continuing"
   exit 0
fi

grep $lv $file | grep -i "$mount. "
if [ $? -eq 0 ]; then
   sed -e '/^\/dev\/mapper\/root_vg-cs.*\/cs. /s/^/#/' -i $file
fi

grep "$mount" $file

echo "" >> $update_log 2>&1
echo "INFO : Finished 1a_unmount_cs.sh at $(timestamp)" >> $update_log 2>&1
echo "INFO : Finished 1a_unmount_cs.sh at $(timestamp)"
echo "################################################" >> $update_log 2>&1
