#compdef cancel

local job_id_list=$(squeue -o '%64i %7P %3t %6b %5q %7Q %5D %12M %R' -u $(whoami) | tail -n +2 | awk '{printf $1; $1=""; print ":" $0;}')
local job_name_list=$(squeue -o '%64j %7P %3t %6b %5q %7Q %5D %12M %R' -u $(whoami) | tail -n +2 | awk '{printf $1; $1=""; print ":" $0;}')
local completion_list=("${(@f)$(echo "${job_name_list}\n${job_id_list}")}")
_describe 'cancel' completion_list
