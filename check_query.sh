# !/bin/bash

script=$(readlink -f "$0")
script_path=$(dirname "$script")

echo "------------------------------------------------------------"
echo assert that the filers of differnt dbs are same 
cat $script_path/queries/db/redshift/2/4.sql | grep "'"
cat $script_path/queries/db/mysql/2/4.sql | grep "'"
cat $script_path/queries/db/postgresql/2/4.sql | grep "'"


echo "------------------------------------------------------------"
echo assert that the filers of differnt dbs are same
cat $script_path/queries/db/redshift/2/2.sql | grep "'"
cat $script_path/queries/db/mysql/2/2.sql | grep "'"
cat $script_path/queries/db/postgresql/2/2.sql | grep "'"

echo "------------------------------------------------------------"
echo assert that the filers of differnt baches are different
cat $script_path/queries/db/redshift/1/4.sql | grep "'"
cat $script_path/queries/db/redshift/2/4.sql | grep "'"
cat $script_path/queries/db/redshift/3/4.sql | grep "'"
cat $script_path/queries/db/redshift/4/4.sql | grep "'"
cat $script_path/queries/db/redshift/5/4.sql | grep "'" 
cat $script_path/queries/db/redshift/6/4.sql | grep "'" 
cat $script_path/queries/db/redshift/7/4.sql | grep "'" 
cat $script_path/queries/db/redshift/8/4.sql | grep "'" 
cat $script_path/queries/db/redshift/9/4.sql | grep "'" 
cat $script_path/queries/db/redshift/10/4.sql | grep "'" 
echo "------------------------------------------------------------"
echo assert that the filers of differnt baches are different
cat $script_path/queries/db/redshift/1/10.sql | grep "'"
cat $script_path/queries/db/redshift/2/10.sql | grep "'"
cat $script_path/queries/db/redshift/3/10.sql | grep "'"
cat $script_path/queries/db/redshift/4/10.sql | grep "'"
cat $script_path/queries/db/redshift/5/10.sql | grep "'" 
cat $script_path/queries/db/redshift/6/10.sql | grep "'" 
cat $script_path/queries/db/redshift/7/10.sql | grep "'" 
cat $script_path/queries/db/redshift/8/10.sql | grep "'" 
cat $script_path/queries/db/redshift/9/10.sql | grep "'" 
echo "------------------------------------------------------------"
echo assert that the filers of differnt baches are different
cat $script_path/queries/db/mysql/1/20.sql | grep "'"
cat $script_path/queries/db/mysql/2/20.sql | grep "'"
cat $script_path/queries/db/mysql/3/20.sql | grep "'"
cat $script_path/queries/db/mysql/4/20.sql | grep "'"
cat $script_path/queries/db/mysql/5/20.sql | grep "'" 
cat $script_path/queries/db/mysql/6/20.sql | grep "'" 
cat $script_path/queries/db/mysql/7/20.sql | grep "'" 
cat $script_path/queries/db/mysql/8/20.sql | grep "'" 
cat $script_path/queries/db/mysql/9/20.sql | grep "'" 
echo "------------------------------------------------------------"

