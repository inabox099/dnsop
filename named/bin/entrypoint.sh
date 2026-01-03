#!/bin/bash

set -e

# Start the proxy socket in the background
#echo "Starting proxy socket..."
#~/bin/proxy_socket.sh start

# Capture the PID of the proxy socket process
#PROXY_SOCKET_PID=$!

# Function to handle termination signals
cleanup() {
    #echo "Stopping proxy socket..."
    #kill "$PROXY_SOCKET_PID"
    #wait "$PROXY_SOCKET_PID"
    #echo "Proxy socket stopped."
    echo "Stopping named..."
    pkill named
    pkill vector
    sleep 2
    echo "Named stopped."
    exit 0
}

/usr/bin/vector &
sleep 2

# Trap termination signals to clean up properly
trap cleanup SIGINT SIGTERM

# Start named (DNS server)
echo "Starting named..."

/usr/sbin/named -u named -f -c /etc/named/named.conf &

NAMED_PID=$!

while true; do
    sleep 1;
done