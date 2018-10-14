#!/bin/bash

check_directly_run_tc tc_oss_basic_test.sh
source $(dirname $0)/../lib/lib_oss.sh

TP_NAME_PARAM_NUM=1

typeset FILE="/etc/hosts"
typeset KEY=$(basename $FILE)
typeset GENERIC_DOMAIN_DOWNLOAD_FILE=$KEY.generic_domain
typeset PATH_STYLE_DOWNLOAD_FILE=$KEY.path_style

function tc_oss_basic_test {
    typeset endpoint=${1?}
    typeset region=${2?}

    typeset standard_out=$(run_tp tp_host_resolve $endpoint)
    typeset generic_out=$(run_tp tp_host_resolve generic.$endpoint)
    typeset out=$(echo "$standard_out")$(echo -e "\n$generic_out")
    out=$(echo "$out" | sort -u)

    for vip in $(echo $out); do
        run_tp tp_vip_connectivity $vip
    done

    typeset bucket="$region-$BUCKET_SUFFIX"
    run_tp tp_put_object $endpoint/$bucket $FILE
    run_tp tp_put_object $bucket.$endpoint $FILE
    run_tp tp_get_object $endpoint/$bucket/$KEY $WS/$PATH_STYLE_DOWNLOAD_FILE
    run_tp tp_get_object $bucket.$endpoint/$KEY $WS/$GENERIC_DOMAIN_DOWNLOAD_FILE
}

function tp_host_resolve {
    typeset endpoint=${1?}

    typeset out
    out=$(log_eval host $endpoint)
    typeset -i rc=$?
    if (( rc != 0 )); then
        return $rc
    fi

    echo "$out" | grep -v "is an alias" | awk '{print $4}'

    typeset num_vip=$(echo "$out" | grep -v "is an alias" | wc -l)
    (( $num_vip > 0 )) || return 1
}

function tp_vip_connectivity {
    typeset vip=${1?}
    typeset out
    out=$(log_eval ping -c1 $vip)
    typeset -i rc=$?
    return $rc
}

function tp_put_object {
    typeset url=${1?}
    typeset file=${2?}

    typeset out

    out=$(log_eval _put_object "$url" "$file" $(basename "$file"))
    typeset -i rc=$?
    check_output $rc "$out" || return 1
}

function tp_get_object {
    typeset url=${1?}
    typeset download_file=${2?}

    typeset out
    out=$(log_eval _get_object "$url" "$download_file")
    typeset -i rc=$?
    check_output $rc "$out" || return 1
    check_output_file "$download_file" || return 1

    diff "$download_file" $FILE || return 1
}

