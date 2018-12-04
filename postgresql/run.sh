# !/bin/bash
# ./run.sh aa00 tpch_1g postgresql 
# ./run.sh aa00 tpch_1g postgresql 3

script=$(readlink -f "$0")
script_path=$(dirname "$script")

server=${1:-aa00}
database=${2:-tpch_1g}
db_type=${3:-postgresql}
db_password=${4:-tpch}
db_port=${5:-5432}
query_id=${6}
if [ "$db_type" = "redshift" ] ; then
  query_path=$script_path/query/redshift
else
  query_path=$script_path/query
fi
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
  echo psql -h $server -U tpch -d $database -p $db_port -f $query_path/$i.sql
  elasped_time="$(time (PGPASSWORD=$db_password psql -h $server -U tpch -d $database -p $db_port -f $query_path/$i.sql >> $log_path) 2>&1 )"
  echo `date +%Y-%m-%d-%H:%M:%S`: elaspe_time = $elasped_time seconds | tee -a $log_path
  echo "$test_time,$database,$db_type,$i,$elasped_time" >> $output_path
  i=`expr $i + 1`
done
echo '-------------------------------------------------------' | tee -a $log_path
echo `date +%Y-%m-%d-%H:%M:%S`: finish tpc-h | tee -a $log_path

