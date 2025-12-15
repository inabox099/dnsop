#!/bin/sh

while true; do
    dig -f /root/fqdn.txt @$NAMESERVER +short > /dev/null 2>&1

    sleep 1
done