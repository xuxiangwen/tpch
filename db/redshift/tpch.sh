# !/bin/bash

script=$(readlink -f "$0")
script_path=$(dirname "$script")

source $script_path/tpch.conf

scale=${1:-1}
batch_id=${2:-1}
query_id=${3}

output_path=$script_path/tpch.csv
log_path=$script_path/tpch.log

TIMEFORMAT=%3R

echo '=========================================================' >> $log_path
test_time=`date +%Y-%m-%d-%H:%M:%S`
echo $test_time: start tpc-h with batch_id=$batch_id on tpch_${scale}g | tee -a $log_path

if [ "$query_id" = "" ] ; then
  i=1
  n=23
else
  i=$query_id
  n=`expr $query_id + 1`
fi

while [ $i -lt $n ]
do
  echo '-------------------------------------------------------' | tee -a $log_path
  echo `date +%Y-%m-%d-%H:%M:%S`: run query $query_path/$batch_id/$i.sql  | tee -a $log_path
  elasped_time="$(time (PGPASSWORD=$db_password psql -h $db_server -U $db_user -d tpch_${scale}g -p $db_port -f $query_path/$batch_id/$i.sql >> $log_path) 2>&1 )"
  echo `date +%Y-%m-%d-%H:%M:%S`: elaspe_time = $elasped_time seconds | tee -a $log_path
  echo "$instance,$database,$test_time,tpch_${scale}g,$batch_id,$i,$elasped_time" >> $output_path
  i=`expr $i + 1`
done
echo '-------------------------------------------------------' | tee -a $log_path
echo `date +%Y-%m-%d-%H:%M:%S`: finish tpc-h with batch_id=$batch_id on tpch_${scale}g | tee -a $log_path
