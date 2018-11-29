# !/bin/bash
script=$(readlink -f "$0")
script_path=$(dirname "$script")

clean_time=`date +%Y-%m-%d-%H-%M-%S`
mkdir -p $script_path/history
if [ -f $script_path/tpch.csv  ]; then
  mv -f $script_path/tpch.csv $script_path/history/tpch.csv.$clean_time
fi
if [ -f $script_path/tpch.log  ]; then
  mv -f $script_path/tpch.log $script_path/history/tpch.log.$clean_time
fi
echo test_time,database,db_type,query_id,query_time > $script_path/tpch.csv
echo > $script_path/tpch.log
echo 'done'


