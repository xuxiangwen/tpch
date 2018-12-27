# !/bin/bash
script=$(readlink -f "$0")
script_path=$(dirname "$script")

source $script_path/tpch.conf

sql_file=${1:-dss.db}
$script_path/sql_file.sh $script_path/dss.db $db_name $db_admin_user $db_admin_password

