#!/bin/bash

_cancel_completions() {
    local truncated_line=(${COMP_LINE:0:$COMP_POINT})
    local job_name_list=$(squeue -o '%64j' -u $(whoami) | tail -n +2 | awk '{print $1;}')
    local job_id_list=$(squeue -o '%64i' -u $(whoami) | tail -n +2 | awk '{print $1;}')
    local completion_list=$(echo ${job_name_list} ${job_id_list} | sort | uniq)
    COMPREPLY=($(compgen -W "${completion_list}" -- "${truncated_line[$COMP_CWORD]}"))
}

complete -F _cancel_completions cancel
