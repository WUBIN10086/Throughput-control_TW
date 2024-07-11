#!/bin/bash
#This scripts control incomming and outcomming bandwight in a linux router box

dir=/home/pi/fairness_AP1
unit=mbit
# Interface connect to out lan
int1="wlan0"
# Interface virtual for incomming traffic
tin1="ifb0"

totalDatarate=$(< $dir/set_target_throughput.tmp wc -l)

w=1
while [ $w -le $totalDatarate ]
do
  IP[$w]=$(awk -v var=$w 'FNR==var{print $1}' $dir/set_target_throughput.tmp)
  datarate[$w]=$(awk -v var=$w 'FNR==var{print $2}' $dir/set_target_throughput.tmp)
  w=$(( w+1 ))
done

w=1
total_th=0
while [ $w -le $totalDatarate ]
do
  total_th=$(echo "scale=10; $total_th + ${datarate[$w]};" | bc -l) # add the total datarate for parent class
  w=$(( w+1 ))
done

modprobe ifb numifbs=1
sudo ip link set dev $tin1 up

## Limit incomming traffic ( to localhost)
# Clean interface
sudo tc qdisc del dev $int1 handle ffff: ingress
#modprobe -r ifb
sudo tc qdisc del root dev $tin1
sudo tc qdisc add dev $int1 handle ffff: ingress
# Redirect  ingress wlan0 to egress ifb0
sudo tc filter add dev $int1 parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev $tin1
# Add classes per ip
sudo tc qdisc add dev $tin1 root handle 2: htb default 80

sudo tc class add dev $tin1 parent 2: classid 2:1 htb rate $total_th$unit  # create parent class

# distribute data rate to the host (child class)
w=1
class_id=10
while [ $w -le $totalDatarate ]
do
sudo tc class add dev $tin1 parent 2:1 classid 2:$class_id htb rate ${datarate[$w]}$unit ceil ${datarate[$w]}$unit
w=$(( w+1 ))
class_id=$(( class_id+10 ))
done

w=1
class_id=10
while [ $w -le $totalDatarate ]
do
sudo tc filter add dev $tin1 parent 2: protocol ip prio 1 u32 match ip src ${IP[$w]} flowid 2:$class_id
w=$(( w+1 ))
class_id=$(( class_id+10 ))
done


