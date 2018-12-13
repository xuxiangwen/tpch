# !/bin/bash
script=$(readlink -f "$0")
script_path=$(dirname "$script")

source $script_path/tpch.conf

scale_list=${1:-1 3 10 30}
data_scale=${2}

old_path=`pwd`
tables="region nation supplier customer part partsupp orders lineitem"

for scale in $scale_list
do
  echo -----------------------------------------------------------
  if [ "$data_scale" = ""  ]; then
    real_scale=$scale
  else
    real_scale=$data_scale
  fi
  echo `date +%Y-%m-%d-%H:%M:%S`: start load ${real_scale}g data
  for table in $tables
  do
    echo `date +%Y-%m-%d-%H:%M:%S`: load $table
    cd $data_path/${real_scale}g
    $script_path/sql.sh "load data local INFILE '$table.tbl' INTO TABLE $table FIELDS TERMINATED BY '|';"  tpch_${scale}g 
  done
  echo `date +%Y-%m-%d-%H:%M:%S`: finish load ${real_scale}g data
  $script_path/sql_file.sh $script_path/dss.check  tpch_${scale}g 
  echo `date +%Y-%m-%d-%H:%M:%S`: done
  echo -----------------------------------------------------------
done

cd $old_path
