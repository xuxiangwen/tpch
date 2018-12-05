# !/bin/bash
script=$(readlink -f "$0")
script_path=$(dirname "$script")

source $script_path/tpch.conf

scale_list=${1:-1 3 10 30}

for scale in $scale_list
do
  echo -----------------------------------------------------------
  $script_path/psql.sh tpch_${scale}g $script_path/dss.ddl
done
