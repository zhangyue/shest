#!/bin/bash

function _get_sys_ip {
    if which ip > /dev/null 2>&1; then
        typeset ip_cmd="ip addr show eth0"
    elif which ifconfig > /dev/null 2>&1; then
        typeset ip_cmd="ifconfig eth0"
    else
        log_warn "Failed to determin system IP. Use 0.0.0.0 instead."
        echo "0.0.0.0"
    fi
    log_eval $(echo $ip_cmd) > /dev/null
    typeset ip=$($(echo $ip_cmd) |grep -w inet | awk '{print $2}' | cut -d\/ -f1)
    log_info "System IP: $ip"
    echo $ip
}

function _get_hostname {
    if which hostname > /dev/null 2>&1; then
        hostname | awk '{print $1}'
    else
        log_warn "Failed to determine host name."
        echo "unknown"
    fi
}

function _get_current_time_millis {
    typeset current_time_millis=$(date +%s%3N)
    if [[ $current_time_millis =~ [[:digit:]]*N ]]; then
        current_time_millis=$(date +%s)000 # Evil Mac OS
    fi
    echo $current_time_millis
}
