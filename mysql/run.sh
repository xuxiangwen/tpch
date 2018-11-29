# !/bin/bash
# ./run.sh aa00 tpch_1g mysql 
# ./run.sh aa00 tpch_1g mysql 3

script=$(readlink -f "$0")
script_path=$(dirname "$script")

server=${1:-aa00}
database=${2:-tpch_1g}
db_type=${3:-mysql}
query_id=${4}
query_path=$script_path/query
output_path=$script_path/tpch.csv
log_path=$script_path/tpch.log

TIMEFORMAT=%3R

echo '=========================================================' >> $log_path
test_time=`date +%Y-%m-%d-%H:%M:%S`
echo $test_time: start tpc-h | tee -a $log_path

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
  echo `date +%Y-%m-%d-%H:%M:%S`: run query $i | tee -a $log_path
  elasped_time="$(time (mysql  -h $server -u tpch -ptpch  -P 3306 $database < $query_path/$i.sql >> $log_path) 2>&1 )"
  echo `date +%Y-%m-%d-%H:%M:%S`: elaspe_time = $elasped_time seconds | tee -a $log_path
  echo "$test_time,$database,$db_type,$i,$elasped_time" >> $output_path
  i=`expr $i + 1`
done
echo '-------------------------------------------------------' | tee -a $log_path
echo `date +%Y-%m-%d-%H:%M:%S`: finish tpc-h | tee -a $log_path

