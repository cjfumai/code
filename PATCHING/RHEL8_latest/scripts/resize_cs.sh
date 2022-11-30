#!/bin/sh

# if root_vg exists and is at least 400GB, and cs is an lv
# then we can shrink cs 

vg=root_vg
vgs --noheadings | grep -i $vg > /dev/null 2>&1
if [ $? -eq 0 ]; then

checkval=400
vgsize=`vgdisplay $vg | grep -i "VG Size" | awk '{print $3}'`
vgsize=`echo $vgsize | bc -l | xargs printf "%.0f"`

if [[ $vgsize -lt $checkval ]]; then
   echo "$vg is $vgsize too small to shrunk /cs - please review /cs before patching"
   exit
fi

vgs
systemctl stop lldpd
mount /cs
e2fsck /dev/root_vg/cs
lvresize --resizefs --size 400G /dev/root_vg/cs
mount /cs
df -h /cs
vgs

else
  echo "root_vg not found exiting..."
fi

exit 0
