#!/bin/bash

typeset BUCKET_SUFFIX=simple-test

function _get_md5_base64 {
    typeset file=${1?}
    cat $file | openssl dgst -md5 -binary | openssl enc -base64
}

function _is_mac_os {
    [[ $(uname) == Darwin ]]
}

function _get_file_length {
    typeset file=${1?}

    if _is_mac_os; then
        stat -f%z $file
    else
        stat --printf="%s" $file
    fi
}

function _put_object {
    typeset url=${1?}
    typeset file=${2?}
    typeset obj_key=${3?}

    typeset content_type md5
    typeset -i size

    content_type="application/octet-stream"
    md5=$(_get_md5_base64 $file) || return 1
    size=$(_get_file_length $file) || return 1

    typeset cmd="curl -H \"Content-MD5: $md5\" -H \"Content-Type: $content_type\" \
            -H \"Content-Length: $size\" -T $file http://$url/$obj_key"
    log_eval $cmd
}

function _get_object {
    typeset url=${1?}
    typeset out_file=${2?}

    mkdir -p $(dirname "$out_file")
    log_eval curl -X GET "$url" --out "$out_file"
}

function _delete_object {
    typeset url=${1?}

    log_eval curl -X DELETE "$url"
}

typeset -i KB=1024
typeset -i MB=$(($KB * 1024))

function _get_file_size {
    typeset path_to_file=${1?}

    if ! [[ -f $path_to_file ]]; then
        echo -1
        return
    fi

    ls -l "$path_to_file" | awk '{print $5}'
}

function _print_throughput {
    typeset -i throughput_byte=${1?}
    typeset -i throughput_kb=$((throughput_byte / $KB))
    typeset -i throughput_mb=$((throughput_byte / $MB))

    if ((throughput_byte < KB)); then
        log_info "$throughput_byte B/s"
        summary_n "$throughput_byte B/s - "
    elif ((throughput_byte < MB * 2)); then
        log_info "$throughput_kb KB/s"
        summary_n "$throughput_kb KB/s - "
    else
        log_info "$throughput_mb MB/s"
        summary_n "$throughput_mb MB/s - "
    fi
}

function _generate_file {
    typeset path_to_file=${1?}
    typeset -i size=${2?}

    if (( $(_get_file_size "$path_to_file") == $size )); then
        return
    fi

    typeset size_mb=$(($size / $MB))
    typeset size_remainder=$(($size % $MB))

    typeset -i rc1 rc2

    dd if=/dev/urandom of="$path_to_file" bs=$MB count=$size_mb 2>&1
    rc1=$?
    dd if=/dev/urandom of="${path_to_file}.remainder" bs=1 count=$size_remainder 2>&1
    rc2=$?
    if (( rc1 != 0 )) || (( rc2 != 0 )); then
        log_error "Failed to generate data file $path_to_file."
        return 1
    fi

    cat "${path_to_file}.remainder" >> "$path_to_file"
    rm -f "${path_to_file}.remainder"

    log_eval ls -l $path_to_file
}

