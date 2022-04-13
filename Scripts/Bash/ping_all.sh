#!/bin/bash
while read host;
do
ping -c1 $host > /dev/null 2>&1
if [ $? != 0 ]; then
        echo "$host is not available"
fi
done < server_list.txt
