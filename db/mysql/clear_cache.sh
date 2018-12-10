# !/bin/bash
script=$(readlink -f "$0")
script_path=$(dirname "$script")

source $script_path/tpch.conf

echo `date +%Y-%m-%d-%H:%M:%S` : clear cache 
$script_path/sql.sh "RESET QUERY CACHE;"  $db_name $db_admin_user $db_admin_password

