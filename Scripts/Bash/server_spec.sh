#!/bin/bash
# get basic server specification

lscpu | egrep "^CPU\(s\)" | awk '{print "CPU: " $2}'

free -h | grep Mem | awk '{print "RAM: " $2}'

#lsblk | grep disk | awk '{print $1, $4, $6}' | sort -k2 -n

lsblk -b | grep disk | awk '{sum += $4;} END {print "HDD: " sum/1024/1024/1024 "G"}'
