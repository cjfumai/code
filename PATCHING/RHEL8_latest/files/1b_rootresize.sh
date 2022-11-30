#!/bin/sh
# 
# v1.0 Chris Fumai: Automate resizing root as part of update
# v2.0 Chris Fumai: additional checks added
#   - check if enough space already in root_vg
#   - check if /cs is in root_vg, if not exit and have operator check manually
#   - check if /cs is a separate fs in fstab and mounted and is a ext4 or xfs
#   - check if /cs is seperate lv and reduce cs lv by 35G only to support additional /boot space needed
# v2.1 Chris Fumai: additional checks added if /cs is not in root_vg
#                   commented out all e2fsck checks. not required if not unmounting /cs

logdir=/var/log
shortdate=`date +%d%m%y`
update_log=$logdir/"OS_update_log_"$shortdate".out"
timestamp() {
  date +"%T:%d%m%y" # use with $(timestamp)
}

echo "################################################" >> $update_log 2>&1
echo "INFO : Starting 1_resizeroot.sh at $(timestamp)" >> $update_log 2>&1
echo "INFO : Starting 1_resizeroot.sh at $(timestamp)"

vg=root_vg
root_free_required=32
root_vg_free=`vgs $vg | awk '{print $7}' | grep -v ^VFree  | sed s'/[g|<]//g' | xargs printf "%.0f"`
if [ $root_vg_free -lt $root_free_required ]; then
   echo "$vg free space is $root_vg_free Gb - $vg will have to be resized - continuing checks" >> $update_log 2>&1
   echo "$vg free space is $root_vg_free Gb - $vg will have to be resized - continuing checks"
else
   echo "$vg has enough free space - $root_free_required Gb - exiting resize process"
   exit 0 
fi

grep -i "/cs " /etc/fstab | egrep -i '(ext4|xfs)'
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

vgs --noheadings | grep -i $vg > /dev/null 2>&1
if [ $? -eq 0 ]; then
   checkval=300
   vgsize=`vgdisplay $vg | grep -i "VG Size" | awk '{print $3}'`
   vgsize=`echo $vgsize | bc -l | xargs printf "%.0f"`
fi

if [ $vgsize -lt $checkval ]; then
   echo "$vg is $vgsize Gb too small to shrink /cs - please review /cs before updating" >> $update_log 2>&1
   echo "$vg is $vgsize Gb too small to shrink /cs - please review /cs before updating"
   exit 1
else
   echo "$vg is larger then $checkval Gb OK - continuing"
fi

echo "e2fsck of /dev/root_vg/cs" >> $update_log 2>&1
echo "e2fsck of /dev/root_vg/cs"
e2fsck /dev/root_vg/cs

if [ $? -eq 0 ]; then
   echo "e2fsck of /dev/root_vg/cs OK" >> $update_log 2>&1
   echo "e2fsck of /dev/root_vg/cs OK"
else
   echo "e2fsck of /dev/root_vg/cs NOT OK - PLEASE CHECK `hostname` lvs and vgs output" >> $update_log 2>&1
   echo "e2fsck of /dev/root_vg/cs NOT OK - PLEASE CHECK `hostname` lvs and vgs output"
   exit 1
fi

cs_reduce_by=35G # reduce cs to support additional /boot space required
echo "lvresize of /dev/root_vg/cs reduce by $cs_reduce_by" >> $update_log 2>&1
echo "lvresize of /dev/root_vg/cs by $cs_reduce_by"
lvresize --resizefs --size -$cs_reduce_by /dev/root_vg/cs

if [ $? -eq 0 ]; then
   echo "lvresize of /cs OK" >> $update_log 2>&1
   echo "lvresize of /cs OK"
else
   echo "lvresize of /cs NOT OK - PLEASE CHECK `hostname` lvs and vgs output" >> $update_log 2>&1
   echo "lvresize of /cs NOT OK - PLEASE CHECK `hostname` lvs and vgs output" >> $update_log 2>&1
   exit 1
fi

echo "" >> $update_log 2>&1
echo "INFO : Finished 1_resizeroot.sh at $(timestamp)" >> $update_log 2>&1
echo "INFO : Finished 1_resizeroot.sh at $(timestamp)"
echo "################################################" >> $update_log 2>&1
