#!/usr/bin/env bash
set -e
snapname=$(echo $1 | tr ' ' '-')
message="hello world"

for vm in master worker1; do
	virsh shutdown $vm 2>/dev/null || true
	virsh snapshot-create-as $vm $snapname $snapname --atomic
	virsh snapshot-list $vm
done
