#!/bin/bash
#
# Removal of OpenOnload content from machines in question
# Will need expansion to remove other content
#
# v1.0 Chris Fumai 2/22: RHEL 8

logdir=/var/log
shortdate=`date +%d%m%y`
update_log=$logdir/"OS_update_log_"$shortdate".out"
timestamp() {
  date +"%T:%d%m%y" # use with $(timestamp)
}

echo "################################################" >> $update_log 2>&1
echo "INFO : $(timestamp) Starting 5_run_OS_yum_update.sh" >> $update_log 2>&1
echo "INFO : $(timestamp) Starting 5_run_OS_yum_update.sh"

echo "" >> $update_log 2>&1
echo "INFO : $(timestamp) Starting yum install of the kernel rpm's" >> $update_log 2>&1
echo "INFO : $(timestamp) Starting yum install of the kernel rpm's"
echo "" >> $update_log 2>&1
yum clean all >> $update_log 2>&1

# ensure onload is removed
/bin/rpm -qa | grep onload  >> $update_log 2>&1
onload_detect=`/bin/rpm -qa | grep -i onload* | wc -l` >> $update_log 2>&1
if [ "$onload_detect" -ge 1 ]
then
  echo "INFO : $(timestamp) Found onload installed, removing"  >> $update_log
  echo "INFO : $(timestamp) Found onload installed, removing"

  yum -y remove onload* >> $update_log 2>&1

fi

yum clean all >> $update_log 2>&1
#
# Now intall a specific kernel so the old one is retained
#
# RHEL8
yum -y --disablerepo=* --enablerepo=rhel-8-for-x86_64-baseos-rpms --enablerepo=rhel-8-for-x86_64-appstream-rpms install kernel-4.18.0-305.25.1.el8_4.x86_64 >> $update_log 2>&1
if [ $? -ne 0 ]
then
  echo "ERROR : $(timestamp) yum Kernel install actions completed with a Non-Zero exit code"
  echo "ERROR : $(timestamp) yum Kernel install actions completed with a Non-Zero exit code" >> $update_log 2>&1
  exit 1
fi

echo "INFO : $(timestamp) Starting yum update of the kernel tool rpm's" >> $update_log 2>&1
echo "INFO : $(timestamp) Starting yum update of the kernel tool rpm's"

#Now wupdate the tools and tools-lib to match the release

yum -y update --disablerepo=* --enablerepo=rhel-8-for-x86_64-baseos-rpms --enablerepo=rhel-8-for-x86_64-appstream-rpms --exclude=kernel  update-to kernel-tools-4.18.0-305.25.1.el8_4.x86_64 kernel-tools-lib-4.18.0-305.el8_4.x86_64
if [ $? -ne 0 ]
then
  echo "ERROR : $(timestamp) yum Kernel tools actions completed with a Non-Zero exit code"
  echo "ERROR : $(timestamp) yum Kernel tools actions completed with a Non-Zero exit code" >> $update_log 2>&1
  exit 1
fi

echo "" >> $update_log 2>&1

echo "INFO : $(timestamp) Starting yum update of the OS rpm's" >> $update_log 2>&1
echo "INFO : $(timestamp) Starting yum update of the OS rpm's"
echo "" >> $update_log 2>&1

yum -y --disablerepo=* --enablerepo=rhel-8-for-x86_64-baseos-rpms --enablerepo=rhel-8-for-x86_64-appstream-rpms --exclude=kernel --exclude=hwloc --exclude=hwloc-libs update >> $update_log 2>&1

if [ $? -ne 0 ]
then
  echo "ERROR : $(timestamp) yum OS update (non-kernel) actions have completed with a Non-Zero exit code"
  echo "ERROR : $(timestamp) yum OS update (non-kernel) actions have completed with a Non-Zero exit code" >> $update_log 2>&1
  exit 1
fi

echo "" >> $update_log 2>&1
echo "INFO : $(timestamp) Finished 5_run_OS_yum_update.sh" >> $update_log 2>&1
echo "INFO : $(timestamp) Finished 5_run_OS_yum_update.sh"
echo "################################################" >> $update_log 2>&1
