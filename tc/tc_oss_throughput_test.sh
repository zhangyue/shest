#!/bin/bash

check_directly_run_tc tc_oss_throughput_test.sh
source $(dirname $0)/../lib/lib_oss.sh
source $(dirname $0)/../lib/lib_system.sh

TP_NAME_PARAM_NUM=3

typeset TEST_DATA_DIR="$(dirname $0)/../test_data"
typeset OBJ_LIST_FILE="$TEST_DATA_DIR/obj_list"

function tc_oss_throughput {
    typeset endpoint=${1?}
    typeset region=${2?}
    typeset num_concurrent=${3?}
    shift; shift; shift
    typeset sizes=$@

    typeset bucket="$region-$BUCKET_SUFFIX"

    mkdir -p $(dirname "$OBJ_LIST_FILE")
    [[ -f "$OBJ_LIST_FILE" ]] && mv "$OBJ_LIST_FILE" "${OBJ_LIST_FILE}.bk.$(date +%Y%m%d-%H%M%S.%3N)"

    for size in $sizes; do
        run_tp tp_put_object_concurrent $endpoint/$bucket $size $num_concurrent
        run_tp tp_get_object_concurrent $endpoint/$bucket $size $num_concurrent
        run_tp tp_del_object_concurrent $endpoint/$bucket $size $num_concurrent
        mv "$OBJ_LIST_FILE" "$OBJ_LIST_FILE.$(date +%Y%m%d-%H%M%S.%3N)"
    done
}

function tc_oss_throughput_no_delete {
    typeset endpoint=${1?}
    typeset region=${2?}
    typeset num_concurrent=${3?}
    shift; shift; shift
    typeset sizes=$@

    typeset bucket="$region-$BUCKET_SUFFIX"

    mkdir -p $(dirname "$OBJ_LIST_FILE")
    [[ -f "$OBJ_LIST_FILE" ]] && mv "$OBJ_LIST_FILE" "${OBJ_LIST_FILE}.bk.$(date +%Y%m%d-%H%M%S.%3N)"

    for size in $sizes; do
        run_tp tp_put_object_concurrent $endpoint/$bucket $size $num_concurrent
        run_tp tp_get_object_concurrent $endpoint/$bucket $size $num_concurrent
        mv "$OBJ_LIST_FILE" "$OBJ_LIST_FILE.$(date +%Y%m%d-%H%M%S.%3N)"
    done
}

function tp_put_object_concurrent {
    typeset url=${1?}
    typeset size=${2?}
    typeset num_concurrent=${3?}

    typeset test_file="$TEST_DATA_DIR/file_$size"
    mkdir -p $(dirname "$test_file")
    log_eval _generate_file "$test_file" $size > /dev/null

    typeset client_id=$(_get_hostname)
    typeset -a pid_list
    typeset err=false

    typeset -i start_time_millis=$(_get_current_time_millis)

    for p_count in $(seq 1 $num_concurrent); do
        typeset out_file="$WS/put.out.$p_count"
        mkdir -p $(dirname "$out_file")
        log_eval _put_object "$url" "$test_file" $(basename "$test_file")-${client_id}-${p_count} > "$out_file" &
        typeset -i pid=$!
        pid_list[$p_count]=$pid
    done

    for p_count in $(seq 1 $num_concurrent); do
        wait ${pid_list[$p_count]}
        typeset -i rc=$?
        typeset out_file="$WS/put.out.$p_count"
        check_output $rc $(cat "$out_file") || err=true
        echo "$url/$(basename "$test_file")-${client_id}-${p_count}" >> "$OBJ_LIST_FILE"
    done

    typeset -i end_time_millis=$(_get_current_time_millis)
    typeset -i time_used_millis=$((end_time_millis - start_time_millis))
    (( time_used_millis == 0 )) && time_used_millis=1
    typeset -i throughput_byte=$((size * 1000 * num_concurrent / time_used_millis))

    _print_throughput $throughput_byte

    if [[ $err == true ]]; then return 1; fi
}

function tp_get_object_concurrent {
    typeset url=${1?}
    typeset -i size=${2?}
    typeset -i num_concurrent=0
    typeset -a pid_list
    typeset err=false

    typeset -i start_time_millis=$(_get_current_time_millis)

    for obj in $(cat "$OBJ_LIST_FILE"); do
        (( num_concurrent++ ))
        typeset download_file="$WS/download_$(basename $obj)"
        typeset out_file="$WS/get.out.$num_concurrent"
        mkdir -p $(dirname "$download_file") $(dirname "$out_file")
        log_eval _get_object "$obj" "$download_file" > "$out_file" &
        typeset -i pid=$!
        pid_list[$num_concurrent]=$pid
    done

    for p_count in $(seq 1 $num_concurrent); do
        wait ${pid_list[$p_count]}
        typeset -i rc=$?
        typeset out_file="$WS/get.out.$p_count"
        check_output $rc $(cat "$out_file") || err=true
    done

    for p_count in $(seq 1 $num_concurrent); do
        typeset download_file="$WS/download_$(basename $obj)"
        check_output_file "$download_file" || return 1
    done

    typeset -i end_time_millis=$(_get_current_time_millis)
    typeset -i time_used_millis=$((end_time_millis - start_time_millis))
    (( time_used_millis == 0 )) && time_used_millis=1
    typeset -i throughput_byte=$((size * 1000 * num_concurrent / time_used_millis))

    _print_throughput $throughput_byte

    if [[ $err == true ]]; then return 1; fi
}

function tp_del_object_concurrent {
    typeset url=${1?}
    typeset -i num_concurrent=0
    typeset -a pid_list
    typeset err=false

    typeset -i start_time_millis=$(_get_current_time_millis)

    for obj in $(cat "$OBJ_LIST_FILE"); do
        (( num_concurrent++ ))
        typeset out_file="$WS/del.out.$num_concurrent"
        mkdir -p $(dirname "$out_file")
        log_eval _delete_object "$obj" > "$out_file" &
        typeset -i pid=$!
        pid_list[$num_concurrent]=$pid
    done

    for p_count in $(seq 1 $num_concurrent); do
        wait ${pid_list[$p_count]}
        typeset -i rc=$?
        typeset out_file="$WS/del.out.$p_count"
        check_output $rc $(cat "$out_file") || err=true
    done

    if [[ $err == true ]]; then return 1; fi
}

