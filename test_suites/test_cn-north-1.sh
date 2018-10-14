#!/bin/bash

typeset dirname=$(dirname $0)
source $dirname/../lib/lib_shest.sh
source $dirname/../tc/tc_oss_basic_test.sh

typeset log_file=$log_dir/test_cn-north-1.log
typeset summary_file=$log_dir/summary_cn-north-1

run_init

run_tc tc_oss_basic_test s3.cn-north-1.jcloudcs.com cn-north-1
run_tc tc_oss_basic_test oss.cn-north-1.jcloudcs.com cn-north-1

