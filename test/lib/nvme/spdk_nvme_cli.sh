#!/usr/bin/env bash

set -e

testdir=$(readlink -f $(dirname $0))
rootdir=$(readlink -f $testdir/../../..)
source $rootdir/scripts/common.sh
source $rootdir/test/common/autotest_common.sh
spdk_nvme_cli="/home/sys_sgsw/nvme-cli"

timing_enter nvme_cli

if [ `uname` = Linux ]; then
	start_stub "-s 2048 -i 0 -m 0xF"
	trap "kill_stub; exit 1" SIGINT SIGTERM EXIT
fi

if [ -d $spdk_nvme_cli ]; then
	bdfs=$(iter_pci_class_code 01 08 02)
	bdf=$(echo $bdfs|awk '{ print $1 }')
	cd $spdk_nvme_cli
	make clean && make
	sed -i 's/spdk=0/spdk=1/g' spdk.conf
	sed -i 's/shm_id=1/shm_id=0/g' spdk.conf
	./nvme list
	./nvme id-ctrl $bdf
	./nvme list-ctrl $bdf
	./nvme get-ns-id $bdf
	./nvme id-ns $bdf
	./nvme fw-log $bdf
	./nvme smart-log $bdf
	./nvme error-log $bdf
	./nvme list-ns $bdf -n 1
	./nvme get-feature $bdf -n 1 -f 1 -s 1 -l 100
	./nvme get-log $bdf -n 1 -i 1 -l 100
	./nvme reset $bdf
fi

if [ `uname` = Linux ]; then
	trap - SIGINT SIGTERM EXIT
	kill_stub
fi

report_test_completion spdk_nvme_cli
timing_exit nvme_cli
