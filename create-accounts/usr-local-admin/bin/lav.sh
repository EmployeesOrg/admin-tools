#!/bin/sh

above=2.5

if [ -e ~dwing/lav.tmp ] 
then 
find /users/dwing/lav.tmp -ctime +2h -maxdepth 0 -exec rm {} \;
fi

if [ ! -e ~dwing/lav.tmp ]
then

lav=`uptime | sed -e "s/.*load averages: \(.*\...\), \(.*\...\),\(.*\...\)/\3/" -e "s/ //g"`

lav_100=`echo "$lav * 100 / 1 " | bc`
above_100=`echo "$above * 100 / 1 " | bc`

if [ $lav_100 -gt $above_100 ]
then
  /usr/sbin/sendmail admin@employees.org \
<<EOF
Subject: `uname -n | cut -d '.' -f 1` LAV is `echo $lav`
From: root@employees.org
To: admin@employees.org

15-minute load average is above `echo $above`.  currently:
  `uptime`

`top -bSI`

`/usr/sbin/iostat -d -x`

`ps -auxwwww`


(this message was generated automatically by /usr/local/admin/bin/lav.sh
via /etc/crontab)
EOF

touch ~dwing/lav.tmp

fi

fi

