#!/usr/bin/env bash
set -ex
message=$1
snapname=$(date +%s)

for vm in master worker1; do
	virsh shutdown $vm || true
	sleep 60
	virsh snapshot-create-as $vm $snapname "$message" --atomic
done
