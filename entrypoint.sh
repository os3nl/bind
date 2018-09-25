#!/bin/sh

/usr/local/sbin/named -f -p 53 -4 &
# -b 127.0.0.1

sleep 2

rndc -c /usr/local/etc/bind/rndc.conf status -p 953 -a 127.0.0.1 -4

#$@
