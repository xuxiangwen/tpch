# !/bin/bash
script=$(readlink -f "$0")
script_path=$(dirname "$script")

source $script_path/tpch.conf

db=${1}
sql=${2}
  
echo PGPASSWORD=$db_password psql -h $db_server -U $db_user -d $db  -p $db_port -f $sql
PGPASSWORD=$db_password psql -h $db_server -U $db_user -d $db  -p $db_port -f $sql
