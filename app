#!/bin/bash

# 本脚本用于为文件名或目录名加入以点号分隔的后缀名。
# 等价于命令'mv xxx xxx.suffix'。
# 与本脚本对应的脚本为rma，用于移除后缀名。
#
# 脚本使用示例：
#     app lr1e-3 exp/train_a exp/train_b exp/train_c
#     以上命令将exp/train_a等三个文件夹分别重命名为exp/train_a.lr1e-3等。
#
# 参数：
#     -f 或 --force：强制修改，即若修改后的名称与已有文件/目录冲突，则覆盖之。

set -euo pipefail

help_message="\
    用于为文件名或目录名加入以点号分隔的后缀名。
    等价于命令'mv xxx xxx.suffix'。
    与本脚本对应的脚本为rma，用于移除后缀名。

参数:
    -f 或 --force：强制修改，即若修改后的名称与已有文件/目录冲突，则覆盖之。

示例：
    app lr1e-3 exp/train_a exp/train_b exp/train_c
"

if [ $# -le 0 ]; then
    echo "${help_message}"
    exit 0
fi

if [ $# -lt 2 ]; then
    echo "ERROR: Too few arguments." >&2
    exit 1
fi

# Some flags
force=false # flag to control if the target can be overwritten

# We use getopt to parse options.
args=$(getopt -l "help,force" -o "hf" -- "$@")
if [ $? != 0 ]; then # there are some errors in the arguments
    echo "ERROR: Some arguments cannot be recognized. Are there any arguments mistaken?" >&2
    exit 1
fi
eval set -- "$args" # rearrange the arguments to a format that can be processed easily

# Parse arguments. The error checking is done after.
while [ $# -ge 1 ]; do
    case "$1" in
        --)
            shift
            break
            ;;
        -h|--help)
            echo "${help_message}"
            exit 0
            ;;
        -f|--force)
            force=true
            shift
            ;;
    esac
done

suffix=${1}
shift 1

for f; do # bash 'for' iterate "$@" by default
    if ! [ -e "${f}" ]; then
        echo "WARNING: File '${f}' doesn't exist. Skipped." >&2
        continue
    fi
    if [ -e "${f}.${suffix}" -a "${force}" = "false" ]; then
        echo "WARNING: File '${f}.${suffix}' exists. Skipped." >&2
        continue
    fi
    mv -f "${f}" "${f}.${suffix}"
done

