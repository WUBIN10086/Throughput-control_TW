#!/bin/bash
#This scripts for delete the traffic shaping from the network.

# Interface connect to out lan
int1="wlan0"
# Interface virtual for incomming traffic
tin1="ifb0"

# Clean interface
sudo tc qdisc del root dev $int1
# Clean interface
sudo tc qdisc del dev $int1 handle ffff: ingress

sudo tc qdisc del root dev $tin1
