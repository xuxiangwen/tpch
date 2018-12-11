# !/bin/bash
script=$(readlink -f "$0")
script_path=$(dirname "$script")

source $script_path/tpch.conf

scale_list=${1:-1 3 10 30}
ddl=${2:-dss.ddl}

for scale in $scale_list
do
  echo -----------------------------------------------------------
  $script_path/sql_file.sh $script_path/$ddl tpch_${scale}g 
done
