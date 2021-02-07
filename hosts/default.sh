# 配置逻辑：
#
# 通过字段ssh_auth_type、send_auth_type、recv_auth_type确定登录、发送（上传）、
# 接收（下载）分别使用何种身份验证方式。
# - 若为none，则不进行自动身份验证（可能需要用户手动输入密码）。当
#   ~/.ssh/config中指定了身份文件时可通过该方式自动验证。
# - 若为password，且password_str字段不为空，则在身份验证时自动输入password_str作
#   为密码。（强烈不建议！）
# - 若为password，且password_str字段为空，则读取password_file指定的文件，并：
#   - 若password_file_encrypted字段为false，则将password_file指定的文件内容作为
#     明文密码自动输入。
#   - 若password_file_encrypted字段为true，则使用命令`_decrypt_password`解密（默
#     认使用gpg进行解密，用户可以修改`_decrypt_password`函数以自定义解密方式），
#     并将解密结果作为明文密码自动输入。
#   - 若为key，则使用identity_file指定的文件作为私钥文件用于身份验证。注意若
#     ~/.ssh/config中已经指定了所需的身份验证文件，则不需选择key方式，可选择none
#     方式。
#   - 若为custom，则分别调用_custom_ssh、_custom_send、_custom_recv函数进行连
#     接、发送和接收。在_custom前缀函数中，用户可以自行设计验证和操作方式。
#
# 通过字段send_type和recv_type确定使用何种方式进行文件发送（上传）和接收（下
# 载）。但当对应的auth_type为custom时，无论如何都将调用_custom前缀函数。
# - 若为scp，则调用scp进行发送/接收。
# - 若为sftp，则调用expect程序自动操作sftp进行发送/接收。
# - 若为custom，则调用命令`_custom_send filepath`进行发送，调用命令
#   `_custom_recv filepath`进行接收。
# 通过remote_dir指定远程目录作为发送（上传）目的地和接收（下载）源目录。若不填，
# 则远程目录默认为"/home/${username}"。特别地，若username为root，则远程目录默认
# 为"/root"。
# 接收（下载）时，远程文件路径可使用以remote_dir为基准的相对路径。
#
# 通过字段mirror_protocol指定用于镜像本地目录与远程目录的协议。脚本默认使用lftp
# 程序进行镜像，故所支持的协议即为lftp支持的协议。此外，若设置为custom，则脚本将
# 调用命令`_custom_upload`和`_custom_download`进行镜像操作。
# 镜像操作使用的身份验证方式由字段send_auth_type和recv_auth_type指定。
# 通过字段dir_map指定本地目录与远程目录间的映射关系，同时可以为每个映射关系指定
# 一个忽略配置文件，每行是一个glob，用于指定该目录中的哪些文件/目录不需镜像。指
# 定目录时，需以'/'结尾。
# 例如：
# *.log
# .git/

hostname=0.0.0.0 # IP或域名
username=$(whoami) # 远程主机用户名
ssh_port=22 # 登录端口
send_port=${ssh_port} # 发送（上传）端口
recv_port=${ssh_port} # 接收（下载）端口
identity_file= # 私钥文件
password_str= # 密码明文字符串
password_file= # 密码文件
password_file_encrypted=false # 密码文件是否被加密
remote_dir= # 发送/接收时的远程目录

ssh_auth_type=custom # 可选项："none"，"password", "key", "custom"
send_auth_type=${ssh_auth_type} # 可选项："none"，"password", "key", "custom"
recv_auth_type=${ssh_auth_type} # 可选项："none"，"password", "key", "custom"

send_type=custom # 可选项："scp", "sftp", "custom"
recv_type=${send_type} # 可选项："scp", "sftp", "custom"
mirror_protocol=sftp # 可选项："sftp"等, 以及"custom"。支持协议详见lftp说明文档
lftp_n_threads=8 # 指定lftp并行上传/下载的文件数，过小会影响镜像操作的速度

# 本地目录与远程目录的映射关系
# 每行格式：本地目录（绝对路径）:远程目录:忽略配置（无则留空，但冒号应保留）
# 如：${HOME}/project:project:${HOME}/project/exclude.txt
dir_map="
"

function _custom_ssh() {
    echo "ERROR: Function '_custom_ssh' is not implemented." 1>&2
    exit 1
}

function _custom_send() {
    echo "ERROR: Function '_custom_send' is not implemented." 1>&2
    exit 1
}

function _custom_recv() {
    echo "ERROR: Function '_custom_recv' is not implemented." 1>&2
    exit 1
}

function _custom_upload() {
    # 在撰写这一函数时，你可以使用变量${local_dir}, ${target_dir}和
    # ${exclude_glob_file}来获取与当前目录对应的本地工作目录，对应的远程目录和忽
    # 略配置文件。
    echo "ERROR: Function '_custom_upload' is not implemented." 1>&2
    exit 1
}

function _custom_download() {
    # 在撰写这一函数时，你可以使用变量${local_dir}, ${target_dir}和
    # ${exclude_glob_file}来获取与当前目录对应的本地工作目录，对应的远程目录和忽
    # 略配置文件。
    echo "ERROR: Function '_custom_download' is not implemented." 1>&2
    exit 1
}

function _decrypt_password() {
    echo $(gpg -q --decrypt ${password_file})
}

