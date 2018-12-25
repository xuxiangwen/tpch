# !/bin/bash
script=$(readlink -f "$0")
script_path=$(dirname "$script")

source $script_path/tpch.conf
log_file=${1}
user=${2:-$db_admin_user}
password=${3:-$db_admin_password}
server=${4:-$db_server}

echo mysqlbinlog \
    --read-from-remote-server \
    --host=$server \
    --port=$db_port  \
    --user $user \
    -p\'$password\' \
    -vv  \
    $log_file
mysqlbinlog \
    --read-from-remote-server \
    --host=$server \
    --port=$db_port  \
    --user $user \
    -p"$password" \
    -vv   \
    $log_file
	
