# !/bin/bash
script=$(readlink -f "$0")
script_path=$(dirname "$script")

source $script_path/tpch.conf

echo PGPASSWORD=$db_admin_password psql -h $db_server -U $db_admin_user -d $db_name -p $db_port
PGPASSWORD=$db_admin_password psql -h $db_server -U $db_admin_user -d $db_name -p $db_port -f $script_path/dss.db
