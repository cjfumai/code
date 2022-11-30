#!/bin/bash
#
# v1.0 Chris Fumai 4 2022: output only errors to stdout for operations

logdir=/var/log
shortdate=`date +%d%m%y`
update_log=$logdir/"OS_prevalidate_log_"$shortdate".out"
timestamp() {
  date +"%T:%d%m%y" # use with $(timestamp)
}

if [ -f $update_log ]; then
	cat $update_log
    echo ""
else
   echo "no $update_log found on `hostname`"
fi

exit 0
