#!/bin/bash

#
# apache watch dog daemon 3.
#

export now=`date '+%Y-%m-%d %H:%M:%S'`
export WDLOGFILE='/var/log/apache2/other_vhosts_error.log'

export DOMAIN=`grep '^domain=' /etc/sellyoursaas.conf | cut -d '=' -f 2`

echo >> /var/log/apache_watchdog3.log
echo "**** ${0} started" >> /var/log/apache_watchdog3.log
#echo $now" Try to detect an apache crash file in /var/crash" >> /var/log/apache_watchdog3.log
echo $now" Try to detect lines 'AH00060: seg fault or similar nasty error detected in the parent process' into $WDLOGFILE" >> /var/log/apache_watchdog3.log 

#echo "${0} ${@}"
#echo "# User id --------> $(id -u)"
#echo "# Now ------------> $now"
#echo "# PID ------------> ${$}"
#echo "# PWD ------------> $PWD" 
#echo "# arguments ------> ${@}"
#echo "# path to me -----> ${0}"
#echo "# parent path ----> ${0%/*}"
#echo "# my name --------> ${0##*/}"
#echo "# realname -------> $(realpath ${0})"
#echo "# realname name --> $(basename $(realpath ${0}))"
#echo "# realname dir ---> $(dirname $(realpath ${0}))"

export EMAILFROM=`grep '^emailfrom=' /etc/sellyoursaas.conf | cut -d '=' -f 2`
export EMAILTO=`grep '^emailsupervision=' /etc/sellyoursaas.conf | cut -d '=' -f 2`
if [ "x$EMAILFROM" == "x" ]; then
	export EMAILFROM=support@$DOMAIN
fi
if [ "x$EMAILTO" == "x" ]; then
	export EMAILTO=supervision@$DOMAIN
fi

export PID=${$}
export scriptdir=$(dirname $(realpath ${0}))

echo "DOMAIN=$DOMAIN" >> /var/log/apache_watchdog3.log
echo "EMAILFROM=$EMAILFROM" >> /var/log/apache_watchdog3.log
echo "EMAILTO=$EMAILTO" >> /var/log/apache_watchdog3.log
echo "PID=$PID" >> /var/log/apache_watchdog3.log

#while [ 1 ] ; do
#sleep 30
#if [ -f /var/crash/_usr_sbin_apache2.0.crash ] ; then
tail -F $WDLOGFILE | grep --line-buffered 'AH00060: seg fault or similar nasty error detected in the parent process' | 
while read ; do
    sleep 5
	export now=`date '+%Y-%m-%d %H:%M:%S'`
	echo "$now ----- Found a segfault, now kicking apache..." >> /var/log/apache_watchdog3.log 2>&1
    sleep 2
	/etc/init.d/apache2 stop >> /var/log/apache_watchdog3.log 2>&1
	sleep 5
	killall -9 apache2 >> /var/log/apache_watchdog3.log 2>&1
	sleep 12
	export now=`date '+%Y-%m-%d %H:%M:%S'`
	echo "$now Now restart apache..." >> /var/log/apache_watchdog3.log 2>&1
	/etc/init.d/apache2 start >> /var/log/apache_watchdog3.log 2>&1

	sleep 2
	echo "Apache seg fault detected by apache_watchdog_daemon3. Apache was killed and started." | mail -aFrom:$EMAILFROM -s "[Warning] Apache seg fault detected on "`hostname`". Apache was killed and started at $now." $EMAILTO

	sleep 2
	echo "ps fauxww | grep apache2 | grep start" >> /var/log/apache_watchdog3.log 2>&1
	ps fauxww | grep apache2 | grep start >> /var/log/apache_watchdog3.log 2>&1
	
	echo "/etc/init.d/apache2 status" >> /var/log/apache_watchdog3.log 2>&1
	/etc/init.d/apache2 status >> /var/log/apache_watchdog3.log 2>&1

	sleep 2
	export now=`date '+%Y%m%d%H%M%S'`
	mv /var/crash/_usr_sbin_apache2.0.crash /var/crash/_usr_sbin_apache2.0.crash."$now" >> /var/log/apache_watchdog3.log 2>&1
#fi
done

# This script never end
