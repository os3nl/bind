#!/bin/sh

/usr/local/sbin/named -f -p 5353 &
# -b 127.0.0.1

sleep 2

rndc -c /usr/local/etc/bind/rndc.conf -p 5353 status

#$@
