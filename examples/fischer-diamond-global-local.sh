#!/bin/bash

# This file is a part of the TChecker project.
#
# See files AUTHORS and LICENSE for copyright details.

# The protocol inspired from:
# "Diamonds Are a Girl’s Best Friend: Partial Order Reduction for Timed Automata
# with Abstractions", Henri Hansen, Shang-Wei Lin, Yang Liu, Truong Khanh
# Nguyen, Jun Sun,
# Computer Aided Verification, 2014

# Check parameters

K=10

function usage() {
    echo "Usage: $0 N";
    echo "       $0 N K";
    echo "       N number of processes";
    echo "       K delay for mutex (default: $K)"
}

if [ $# -eq 1 ]; then
    N=$1
elif [ $# -eq 2 ]; then
    N=$1
    K=$2
else
    usage
    exit 1
fi

# Labels
labels="cs1"
for pid in `seq 2 $N`; do
    labels="${labels},cs${pid}"
done
echo "#labels=${labels}"

# Model

echo "#clock:size:name
#int:size:min:max:init:name
#process:name
#event:name
#location:process:name{attributes}
#edge:process:source:target:event:{attributes}
#sync:events
#   where
#   attributes is a colon-separated list of key:value
#   events is a colon-separated list of process@event
"

echo "system:fischer_global_local_${N}_$K
"

# Events

echo "event:tau"

for pid in `seq 0 $N`; do
    echo "event:id_to_$pid
event:ID_TO_$pid
"
done

echo ""

# Processes

for pid in `seq 1 $N`; do
    echo "# Process $pid
process:P$pid
clock:1:x$pid
int:1:0:$N:0:id$pid
location:P$pid:A{initial:}	
location:P$pid:req{invariant:x$pid<=$K}
location:P$pid:wait{}
location:P$pid:cs{labels:cs$pid}
location:P${pid}:State5{}	
edge:P$pid:A:req:tau{provided:id$pid==0 : do:x$pid=0}
edge:P$pid:req:wait:ID_TO_$pid{provided:x$pid<=$K : do:x$pid=0;id$pid=$pid}
edge:P$pid:wait:req:tau{provided:id$pid==0 : do:x$pid=0}
edge:P$pid:wait:cs:tau{provided:x$pid>$K && id$pid==$pid}
edge:P$pid:cs:State5:ID_TO_0{do: id$pid=0}
edge:P${pid}:State5:A:tau{provided:x${pid}>1}
"
    for id in `seq 0 $N`; do
	echo "edge:P$pid:A:A:id_to_$id{do:id$pid=$id}
edge:P$pid:wait:wait:id_to_$id{do:id$pid=$id}
edge:P$pid:State5:State5:id_to_$id{do:id$pid=$id}"
	
	if [ "$id" -ne "$pid" ]; then
	    echo "edge:P$pid:req:req:id_to_$id{do:id$pid=$id}"
	fi
	if [ "$id" -ne "0" ]; then
	    echo "edge:P$pid:cs:cs:id_to_$id{do:id$pid=$id}"
	fi
    done
echo ""
done

# Synchronisations

for id in `seq 0 $N`; do
    for p in `seq 1 $N`; do
	echo -n "sync:P$p@ID_TO_$id";
	for q in `seq 1 $N`; do
	    if [ "$p" -ne "$q" ]; then
		echo -n ":P$q@id_to_$id"
	    fi
	done;
	echo ""
    done
done

