#!/usr/bin/env bash
set -x
snapname=$(echo $1 | tr ' ' '-')
ssh root@master "shutdown -h now"
ssh root@worker1 "shutdown -h now"
ssh root@worker2 "shutdown -h now"

sleep 15

for vm in master worker1 worker2; do
	virsh shutdown $vm 2>/dev/null || true
done
sleep 15
for vm in master worker1 worker2; do
	virsh shutdown $vm 2>/dev/null || true
	virsh snapshot-create-as $vm $snapname $snapname --atomic
	virsh snapshot-list $vm
	virsh start $vm 2>/dev/null || true
done
