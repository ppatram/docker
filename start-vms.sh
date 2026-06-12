#!/usr/bin/env bash

mode=${1:?Usage: $0 <start|stop> [snapname]}
snapname=$2

VMS=(master worker1 worker2)
TIMEOUT=120
ELAPSED=0

if [ "$mode" = "start" ]; then
	for vm in "${VMS[@]}"; do virsh start $vm 2>/dev/null; done
	while [ $ELAPSED -lt $TIMEOUT ]; do
		ALL_UP=true
		for vm in "${VMS[@]}"; do ping -c1 -w2 $vm &>/dev/null || ALL_UP=false; done
		$ALL_UP && break
		sleep 2; ELAPSED=$((ELAPSED + 2))
	done
	echo "VMs are up, waiting for SSH..."
	ELAPSED=0
	while [ $ELAPSED -lt $TIMEOUT ]; do
		ALL_SSH=true
		for vm in "${VMS[@]}"; do ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no $vm "hostname" &>/dev/null || ALL_SSH=false; done
		$ALL_SSH && break
		sleep 2; ELAPSED=$((ELAPSED + 2))
	done

elif [ "$mode" = "stop" ]; then
	[ -z "$snapname" ] && { echo "Usage: $0 stop <snapname>"; exit 1; }
	for vm in "${VMS[@]}"; do virsh shutdown $vm 2>/dev/null; done
	while [ $ELAPSED -lt $TIMEOUT ]; do
		ALL_DOWN=true
		for vm in "${VMS[@]}"; do ping -c1 -w2 $vm &>/dev/null && ALL_DOWN=false; done
		$ALL_DOWN && break
		sleep 2; ELAPSED=$((ELAPSED + 2))
	done
	for vm in "${VMS[@]}"; do virsh snapshot-create-as $vm "$snapname"; done

else
	echo "Unknown mode: $mode"; exit 1
fi
