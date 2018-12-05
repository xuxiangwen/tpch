# !/bin/bash

script=$(readlink -f "$0")
script_path=$(dirname "$script")

target_path=$script_path/data
scale_list=${1:-1 3 10 30}

origin_path=`pwd`


echo `date +%Y-%m-%d-%H:%M:%S`: start generating data
for scale in $scale_list
do  
  echo '======================================================='
  storage_path=$target_path/mysql/${scale}g
  echo `date +%Y-%m-%d-%H:%M:%S`: start generating mysql data in $storage_path
  mkdir -p $storage_path
  file_count=`ls -l $storage_path | grep tbl | wc -l`
  
  if [ $file_count -eq 8 ]; then
    echo `date +%Y-%m-%d-%H:%M:%S`: ${scale}g data has existed in $storage_path
  else  
    echo `date +%Y-%m-%d-%H:%M:%S`: start generating ${scale}g data 
    cd $script_path/tpc-h-tool/dbgen
	rm -rf *.tbl
    ./dbgen -vf -s $scale
    echo `date +%Y-%m-%d-%H:%M:%S`: finish generating ${scale}g data    
	
	echo `date +%Y-%m-%d-%H:%M:%S`: mv all tbl files into $storage_path	
    mkdir -p $storage_path
    mv -f *.tbl $storage_path
  fi
  
  echo `date +%Y-%m-%d-%H:%M:%S`: $storage_path information
  ls -l -h $storage_path    
  du --max-depth=1 -h $storage_path
  echo `date +%Y-%m-%d-%H:%M:%S`: finish generating mysql data in $storage_path
  
  echo '-------------------------------------------------------'
  pg_storage_path=$target_path/postgresql/${scale}g
  echo `date +%Y-%m-%d-%H:%M:%S`: start generating postgres data in $pg_storage_path
  mkdir -p $pg_storage_path
  file_count=`ls -l $pg_storage_path | grep csv | wc -l` 
  
  if [ $file_count -eq 8 ]; then
    echo `date +%Y-%m-%d-%H:%M:%S`: ${scale}g data has existed in $pg_storage_path.
  else  
    echo `date +%Y-%m-%d-%H:%M:%S`: start removing last \|     
    for tbl_file in `ls $storage_path/*.tbl`
	do 
	  echo `date +%Y-%m-%d-%H:%M:%S`: $tbl_file
	  sed 's/|$//' $tbl_file > ${tbl_file/tbl/csv}	  
	done
	mkdir -p $pg_storage_path
    mv -f $storage_path/*.csv $pg_storage_path/   
    echo `date +%Y-%m-%d-%H:%M:%S`: finish removing last \|         
  fi  
  
  echo `date +%Y-%m-%d-%H:%M:%S`: $pg_storage_path information
  ls -l -h $pg_storage_path    
  du --max-depth=1 -h $pg_storage_path  
  echo `date +%Y-%m-%d-%H:%M:%S`: finish generating postgres data in $pg_storage_path
  
  echo '-------------------------------------------------------'
  rs_storage_path=$target_path/redshift/${scale}g
  echo `date +%Y-%m-%d-%H:%M:%S`: start generating redshift data in $rs_storage_path
  mkdir -p $rs_storage_path
  file_count=`ls -l $rs_storage_path | grep lzo | wc -l` 
  
  if [ $file_count -eq 8 ]; then
    echo `date +%Y-%m-%d-%H:%M:%S`: ${scale}g data has existed in $rs_storage_path.
  else  
    echo `date +%Y-%m-%d-%H:%M:%S`: start compress data     
    for csv_file in `ls $pg_storage_path/*.csv`
	do 
	  echo `date +%Y-%m-%d-%H:%M:%S`: $csv_file	 
	  lzop -v $csv_file
	done
	mkdir -p $rs_storage_path
    mv -f $pg_storage_path/*.lzo $rs_storage_path/   
    echo `date +%Y-%m-%d-%H:%M:%S`: finish compress data
  fi  
  
  echo `date +%Y-%m-%d-%H:%M:%S`: $rs_storage_path information
  ls -l -h $rs_storage_path    
  du --max-depth=1 -h $rs_storage_path  
  echo `date +%Y-%m-%d-%H:%M:%S`: finish generating postgres data in $rs_storage_path  

done
cd $origin_path
echo `date +%Y-%m-%d-%H:%M:%S`: finish generating data

