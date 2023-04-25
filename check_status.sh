#!/bin/sh
# $1 is .time file
# $2 is sample ID
# $3 is the name of the rule
# usage: ./check_status $paired_reads.bench {paired_reads} {rule}
# usage: ./check_status $single_reads.bench {single_reads} {rule}
exitStatus=$(grep "Exit status" $1 | cut -d' ' -f3)
mysql -e "use AvA_2; INSERT INTO pipeline_process VALUES ('$2', '$3', '$exitStatus') ON DUPLICATE KEY UPDATE status='$exitStatus'"
