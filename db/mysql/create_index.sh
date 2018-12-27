# !/bin/bash
script=$(readlink -f "$0")
script_path=$(dirname "$script")

source $script_path/tpch.conf

scale_list=${1:-1 3 10 30}
sql_file=${2:-dss.index}

for scale in $scale_list
do
  echo -----------------------------------------------------------
  echo `date +%Y-%m-%d-%H:%M:%S`: start building primary keys and indexes

  while read line
  do 
    echo `date +%Y-%m-%d-%H:%M:%S`: $line
    $script_path/sql.sh "$line" tpch_${scale}g
  done < $script_path/dss.index
  echo `date +%Y-%m-%d-%H:%M:%S`: finish building primary keys and indexes
done
