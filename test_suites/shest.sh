#!/bin/bash

typeset dirname=$(dirname $0)
source $dirname/../lib/lib_shest.sh
source $dirname/../tc/tc_oss_basic_test.sh

typeset log_file=$log_dir/test.log
typeset summary_file=$log_dir/summary

run_init

run_tc tc_oss_basic_test s3.cn-north-1.jcloudcs.com cn-north-1
run_tc tc_oss_basic_test oss.cn-north-1.jcloudcs.com cn-north-1
#run_tc tc_oss_basic_test s3.cn-south-1.jcloudcs.com cn-south-1
#run_tc tc_oss_basic_test oss.cn-south-1.jcloudcs.com cn-south-1
#run_tc tc_oss_basic_test s3.cn-east-1.jcloudcs.com cn-east-1
#run_tc tc_oss_basic_test oss.cn-east-1.jcloudcs.com cn-east-1
#run_tc tc_oss_basic_test s3.cn-east-2.jcloudcs.com cn-east-2
#run_tc tc_oss_basic_test oss.cn-east-2.jcloudcs.com cn-east-2

