#!/bin/bash

typeset WS="/tmp/shest"

typeset -i TC_NUM_TP=0 TC_NUM_FAILED_TP
typeset -i TOTAL_NUM_TP TOTAL_NUM_FAILED_TP

# Number of parameters printed as part of TP name.
# Can be set anywhere as per TC / TP required to get better test summary appearance.
typeset TP_NAME_PARAM_NUM=0

function resolve_home_dir {
    typeset dir_name_0=${1?}
    typeset pwd=${2?}
    if [[ $dir_name_0 =~ ^\/.* ]]; then # /home/user/shest/test_suites/ts.sh
        home_dir="$(dirname $dir_name_0)"
    elif [[ $dir_name_0 =~ ^\.$ ]]; then # ./ts.sh
        home_dir="$(dirname $pwd)"
    elif [[ $dir_name_0 =~ ^\.\/.* ]]; then # ./shest/test_suites/ts.sh
        home_dir="$pwd"/$(dirname $(echo "$dir_name_0" | sed 's/\.\///'))
    else
        home_dir="$pwd/$(dirname $dir_name_0)"
    fi
    echo "$home_dir"
}

typeset home_dir=$(resolve_home_dir $dirname $(pwd))
typeset log_dir=$home_dir/log
typeset log_file=$log_dir/test.log
typeset summary_file=$log_dir/summary

function check_directly_run_tc {
    typeset tc_script_name=${1?}
    if [[ $0 == $tc_script_name ]]; then
        echo "This is a library file and is not expected to be executed directly."
        echo "Run shest.sh or similar test suite script (can be copied from shest.sh) instead."
        echo "See READMD.md for more information."
    fi
}

function check_env {
    mypid=$(echo $$)
    out=$(ps -ef | grep -E "^[[:alnum:]]+\+{0,1}[[:space:]]+$mypid[[:space:]]")
    if ! echo "$out" | grep -q bash; then
        echo "[WARN] Please use bash to run the script."
        echo "e.g. \$script_dir/shest.sh or bash \$script_dir/shest.sh"
        # We do not return 1 for now, as the check is not so accurate in some MacOS system.
        #return 1
    fi
}

function run_init {
    if ! check_env; then
        exit 1
    fi

    mkdir -p "$log_dir"
    echo "Test log: $log_file"
    rm -f "$summary_file"
}

function log_ {
    typeset msg=$*
    echo "$msg" >> "$log_file"
}

function log_info {
    typeset msg=$*
    echo "$(date +%D-%T.%3N) [$BASHPID] INFO - $msg" >> "$log_file"
}

function log_warn {
    typeset msg=$*
    echo "$(date +%D-%T.%3N) [$BASHPID] WARN - $msg" >> "$log_file"
}

function log_error {
    typeset msg=$*
    echo "$(date +%D-%T.%3N) [$BASHPID] ERROR - $msg" >> "$log_file"
}

function log_eval {
    echo "$(date +%D-%T.%3N) [$BASHPID] EVAL - $*" >> "$log_file"
    typeset out
    typeset -i rc
    out=$(eval $* 2>&1)
    rc=$?
    echo "$out"
    if (( rc != 0 )); then
        log_error "RC: $rc"
        log_error "$out"
    else
        log_info "RC: $rc"
        log_info "$out"
    fi
    return $rc
}

function console_info {
    typeset msg=$*
    echo "$(date +%D-%T.%3N) [$BASHPID] INFO - $msg" >&2
}

function console_info_n {
    typeset msg=$*
    echo -n "$(date +%D-%T.%3N) [$BASHPID] INFO - $msg" >&2
}

function summary {
    typeset msg=$*
    echo "$msg" >&2
    echo "$msg" >> $summary_file
}

function summary_n {
    typeset msg=$*
    echo -n "$msg" >&2
    echo -n "$msg" >> $summary_file
}

function tc_start {
    typeset tc_name=${1?}
    shift
    typeset msg=$*
    summary "--------------------------------------------------------------------------------"
    summary "TC $tc_name START @ $(date '+%D-%T.%3N')"
    log_ "================================================================================"
    log_info "TC START: $tc_name"
}

function tc_end {
    typeset tc_name=${1?}
    shift
    typeset msg=$*

    if (( TC_NUM_FAILED_TP == 0 )); then
        summary "TC $tc_name END - $TC_NUM_TP of $TC_NUM_TP passed"
        log_info "TC END: $tc_name - $TC_NUM_TP of $TC_NUM_TP passed"
    else
        summary_n "TC $tc_name END - "
        highlight_red
        summary "$TC_NUM_FAILED_TP of $TC_NUM_TP failed"
        reset_font_color
        log_info "TC END: $tc_name - $TC_NUM_FAILED_TP of $TC_NUM_TP failed"
    fi
}

function run_tc {
    typeset tc_name=${1?}
    shift

    TC_NUM_TP=0
    TC_NUM_FAILED_TP=0

    tc_start $tc_name
    eval $tc_name $@
    tc_end $tc_name
}

function run_tp {
    typeset tp_name=${1?}
    shift

    typeset tp_name_params
    if (( TP_NAME_PARAM_NUM > 0 )); then
        for i in $(seq 1 $TP_NAME_PARAM_NUM); do
            tp_name_params="$tp_name_params $1"
            shift
        done
    else
        tp_name_params=$(echo $@)
    fi

    log_ "--------------------------------------------------------------------------------"
    log_info "TP START: $tp_name $tp_name_params"
    summary_n "TP: $tp_name $tp_name_params ... "

    $tp_name $tp_name_params "$@"
    rc=$?
    if (( rc == 0 )); then
        #highlight_green
        summary "PASS"
        log_info "TP PASS: $tp_name $tp_name_params"
    else
        highlight_red
        summary "FAIL"
        log_info "TP FAIL: $tp_name $tp_name_params"
        (( TC_NUM_FAILED_TP++ )); (( TOTAL_NUM_FAILED_TP++ ))
    fi
    reset_font_color
    (( TC_NUM_TP++ )); (( TOTAL_NUM_TP++ ))
}

function check_output {
    typeset -i rc=${1?}
    typeset out=${2?}
    if (( rc != 0 )) || echo $out | egrep -q '(Error|statusCode)'; then
        return 1
    fi
}

function check_output_file {
    typeset out_file=${1?}
    if egrep -q '(Error|statusCode)' "$out_file"; then
        log_error $(cat "$out_file")
        return 1
    fi
}

function highlight_green {
    printf "\033[0;42m" >&2
}

function highlight_red {
    printf "\033[0;41m" >&2
}

function reset_font_color {
    printf "\033[0;00m" >&2
}

function print_end_banner {
    summary "--------------------------------------------------------------------------------"
}

function print_final_result_pass {
    summary "$TOTAL_NUM_TP of $TOTAL_NUM_TP passed"
}

function print_final_result_fail {
    highlight_red
    summary "$TOTAL_NUM_FAILED_TP of $TOTAL_NUM_TP failed"
    reset_font_color
}

function finally {
    if (( TOTAL_NUM_TP == 0 )); then
        return
    fi

    print_end_banner
    if (( TOTAL_NUM_FAILED_TP == 0 )); then
        print_final_result_pass
    else
        print_final_result_fail
    fi
    echo "Test log: $log_file"
    if (( TOTAL_NUM_FAILED_TP != 0 )); then
        exit 1
    fi
}

trap finally EXIT

