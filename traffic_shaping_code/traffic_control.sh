#!/bin/bash
#This scripts control incomming and outcomming bandwight in a linux router box

dir=/home/pi/fairness_AP1  #指定配置文件的目錄。
unit=mbit  #設定帶寬單位為Mbit。
# Interface connect to out lan
int1="wlan0"  #設定連接到LAN的網路介面
# Interface virtual for incomming traffic
tin1="ifb0"  #設定虛擬介面，用於進入流量

#使用wc -l命令從文件set_target_throughput.tmp中讀取總數據速率。
totalDatarate=$(< $dir/set_target_throughput.tmp wc -l)

#使用awk從文件中讀取每個IP和對應的數據速率，並存儲在陣列IP和datarate中。
w=1
while [ $w -le $totalDatarate ]
do
  IP[$w]=$(awk -v var=$w 'FNR==var{print $1}' $dir/set_target_throughput.tmp)
  datarate[$w]=$(awk -v var=$w 'FNR==var{print $2}' $dir/set_target_throughput.tmp)
  w=$(( w+1 ))
done

#累加所有的數據速率，計算出總數據速率total_th
w=1
total_th=0
while [ $w -le $totalDatarate ]
do
  total_th=$(echo "scale=10; $total_th + ${datarate[$w]};" | bc -l) # add the total datarate for parent class
  w=$(( w+1 ))
done

#使用modprobe載入ifb模組，並將虛擬介面tin1啟用
modprobe ifb numifbs=1
sudo ip link set dev $tin1 up

## Limit incomming traffic ( to localhost)
# Clean interface(清除之前的qdisc設定)
sudo tc qdisc del dev $int1 handle ffff: ingress
#modprobe -r ifb(設定新的qdisc來限制進入流量)
sudo tc qdisc del root dev $tin1
sudo tc qdisc add dev $int1 handle ffff: ingress
# Redirect  ingress wlan0 to egress ifb0(並將wlan0的進入流量重新導向到ifb0)
sudo tc filter add dev $int1 parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev $tin1
# Add classes per ip(新增根類別)
sudo tc qdisc add dev $tin1 root handle 2: htb default 80

#設置總數據速率
sudo tc class add dev $tin1 parent 2: classid 2:1 htb rate $total_th$unit  # create parent class

# distribute data rate to the host (child class)
#為每個IP新增子類別，分配對應的數據速率
w=1
class_id=10
while [ $w -le $totalDatarate ]
do
sudo tc class add dev $tin1 parent 2:1 classid 2:$class_id htb rate ${datarate[$w]}$unit ceil ${datarate[$w]}$unit
w=$(( w+1 ))
class_id=$(( class_id+10 ))
done

#新增過濾器，將流量根據IP匹配到對應的類別
w=1
class_id=10
while [ $w -le $totalDatarate ]
do
sudo tc filter add dev $tin1 parent 2: protocol ip prio 1 u32 match ip src ${IP[$w]} flowid 2:$class_id
w=$(( w+1 ))
class_id=$(( class_id+10 ))
done


