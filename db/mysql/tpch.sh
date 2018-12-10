# !/bin/bash

script=$(readlink -f "$0")
script_path=$(dirname "$script")

source $script_path/tpch.conf

usage() { 
	echo "Usage: $0 [-s <1|3|10|30>] [-b <1|2|3|4>] [-c] [-e] [-q <1}2}3>]" 1>&2
	exit 1
}

while getopts "s:b:ceq:" opt
do
  case $opt in
    s) scale=$OPTARG ;;
    b) batch_id=$OPTARG ;;
    c) clear_cache=1 ;;
    e) explain_plan=1 ;;	
    q) query_id=$OPTARG ;;   	  
    *) usage ;;
  esac
done

if [ -z "${scale}" ] || [ -z "${batch_id}" ]; then
    usage
fi

if [ "$query_id" = "" ] ; then
  i=1
  n=23
else
  i=$query_id
  n=`expr $query_id + 1`
fi

output_path=$script_path/tpch.csv
log_path=$script_path/tpch.log

TIMEFORMAT=%3R
echo '=========================================================' >> $log_path
echo scale=$scale
echo batch_id=$batch_id
echo clear_cache=$clear_cache
echo explain_plan=$explain_plan
echo query_id=$query_id

test_time=`date +%Y-%m-%d-%H:%M:%S`
echo $test_time: start tpc-h with batch_id=$batch_id on tpch_${scale}g | tee -a $log_path

if [ "$clear_cache" = "1" ] ; then
  echo clear cache
  $script_path/clear_cache.sh
fi

while [ $i -lt $n ]
do
  echo '-------------------------------------------------------' | tee -a $log_path
  if [ "$explain_plan" = "1" ] ; then
    echo `date +%Y-%m-%d-%H:%M:%S`: run query $query_path/$batch_id/plan/$i.sql  | tee -a $log_path
    mysql  -h $db_server -u $db_user -p$db_password  -P 3306 tpch_${scale}g < $query_path/$batch_id/plan/$i.sql >> $log_path
  else
    echo `date +%Y-%m-%d-%H:%M:%S`: run query $query_path/$batch_id/$i.sql  | tee -a $log_path
    elasped_time="$(time (mysql  -h $db_server -u $db_user -p$db_password  -P 3306 tpch_${scale}g < $query_path/$batch_id/$i.sql >> $log_path) 2>&1 )"
    echo `date +%Y-%m-%d-%H:%M:%S`: elaspe_time = $elasped_time seconds | tee -a $log_path
    echo "$instance,$database,$test_time,tpch_${scale}g,$batch_id,$i,$elasped_time" >> $output_path
  fi
  i=`expr $i + 1`
done
echo '-------------------------------------------------------' | tee -a $log_path
echo `date +%Y-%m-%d-%H:%M:%S`: finish tpc-h with batch_id=$batch_id on tpch_${scale}g | tee -a $log_path
