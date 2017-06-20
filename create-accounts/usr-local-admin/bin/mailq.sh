#!/bin/sh

toomanymailq=1000
TMPFILE=~/mailq-warned-queue-size.tmp
mailqcount=`mailq | tail | grep Request[s\.] | cut -d " " -f 5`

if [ "$mailqcount" = "" ] ; then exit; fi


if [ $mailqcount -gt $toomanymailq ]
then
  if [ ! -e $TMPFILE ]
  then
    touch $TMPFILE
    /usr/sbin/sendmail admin@employees.org \
<<EOF
Subject: mail queue is $mailqcount
From: root@employees.org
To: admin@employees.org

mail queue is $mailqcount, which exceeds threshold of $toomanymailq.

`/usr/local/bin/qshape -w 50 deferred | head`

(this message was generated automatically by /usr/local/admin/bin/mailq.sh
via /etc/crontab)

EOF
  fi

else
  if [ -e $TMPFILE ]
  then
    rm $TMPFILE
  fi
fi
