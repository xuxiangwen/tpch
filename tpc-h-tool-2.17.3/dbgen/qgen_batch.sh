# !/bin/bash

script=$(readlink -f "$0")
script_path=$(dirname "$script")

base_path=$script_path
target_path=$base_path/batch_queries
times=${1:-10}
db_list=${1:-mysql postgresql redshift}

cd $base_path
rm -rf $target_path
mkdir -p $target_path

echo `date +%Y-%m-%d-%H:%M:%S`: start batch generating queries
for i in `seq 1 $times`
do
  echo `date +%Y-%m-%d-%H:%M:%S`: generating batch $i
  for q in `seq 1 22`
  do
    # generating sql
    DSS_QUERY=templates ./qgen $q >> $target_path/$q.sql  
	
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
      fi
      sed 's/^select/explain select/' $query_path/$q.sql > $explain_path/$q.sql
    done
    rm -rf $target_path/$q.sql 
  done
done

echo `date +%Y-%m-%d-%H:%M:%S`: finish batch generating queries
