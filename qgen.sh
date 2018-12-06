# !/bin/bash

script=$(readlink -f "$0")
script_path=$(dirname "$script")

template_path=$script_path/queries/templates
target_path=$script_path/queries/db
times=${1:-10}
db_list=${2:-mysql postgresql redshift}

origin_path=`pwd`

for db in $db_list
do
  rm -rf $target_path/$db
  mkdir -p $target_path/$db
done

echo `date +%Y-%m-%d-%H:%M:%S`: start batch generating queries
for i in `seq 1 $times`
do
  rand=$RANDOM
  echo `date +%Y-%m-%d-%H:%M:%S`: generating batch $i
  for q in `seq 1 22`
  do
    # generating sql
    cd $script_path/tpc-h-tool/dbgen
    DSS_QUERY=$template_path ./qgen -r $rand $q > $target_path/$q.sql  
	
	#  move sql to the specific database 	
    for db in $db_list
    do 
      query_path=$target_path/$db/$i
      explain_path=$target_path/$db/$i/plan
	  mkdir -p $query_path $explain_path 	 
        
      cp $target_path/$q.sql  $query_path
      if [ "$db" = "redshift" ]; then
         sed -i "s/'\ month/\ months'/g" $query_path/$q.sql
         sed -i "s/1\ months/1\ month/g" $query_path/$q.sql 
         sed -i "s/'\ year/\ year'/g" $query_path/$q.sql 
         sed -i "s/1\ years/1\ year/g" $query_path/$q.sql
         sed -i "s/'\ day/\ days'/g" $query_path/$q.sql        
         sed -i "s/1\ days/1\ day/g" $query_path/$q.sql 
         
         echo set enable_result_cache_for_session to off\; > $query_path/$q.sql.temp
         cat $query_path/$q.sql >> $query_path/$q.sql.temp
         mv $query_path/$q.sql.temp $query_path/$q.sql  
      fi
      sed 's/^select/explain select/' $query_path/$q.sql > $explain_path/$q.sql
    done
    rm -rf $target_path/$q.sql 
  done
done
cd $origin_path
echo `date +%Y-%m-%d-%H:%M:%S`: finish batch generating queries
