#!/bin/bash

typeset dirname=$(dirname $0)
source $dirname/../lib/lib_shest.sh
source $dirname/../tc/tc_oss_throughput_test.sh

typeset log_file=$log_dir/test_throughput.log
typeset summary_file=$log_dir/summary_throughput

run_init

run_tc tc_oss_throughput_no_delete s3.cn-north-1.jcloudcs.com cn-north-1 1 $(( 10 * MB )) $(( 100 * MB ))
run_tc tc_oss_throughput s3.cn-north-1.jcloudcs.com cn-north-1 10 $(( 10 * MB )) $(( 100 * MB ))
#run_tc tc_oss_throughput s3.cn-north-1.jcloudcs.com cn-north-1 20 $(( 10 * MB )) $(( 100 * MB ))
#run_tc tc_oss_throughput s3.cn-north-1.jcloudcs.com cn-north-1 50 $(( 10 * MB )) $(( 100 * MB ))
#run_tc tc_oss_throughput s3.cn-north-1.jcloudcs.com cn-north-1 100 $(( 10 * MB )) $(( 100 * MB ))

