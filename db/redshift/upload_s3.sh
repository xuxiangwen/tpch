# !/bin/bash
script=$(readlink -f "$0")
script_path=$(dirname "$script")

source $script_path/tpch.conf

scale_list=${1:-1 3 10 30}

old_path=`pwd`
tables="region nation supplier customer part partsupp orders lineitem"

for scale in $scale_list
do
  echo -----------------------------------------------------------
  echo `date +%Y-%m-%d-%H:%M:%S`: start uploading ${scale}g data to s3
  aws s3 rm $s3_path/${scale}g --region $s3_region --recursive
  aws s3 cp $data_path/${scale}g $s3_path/${scale}g --region $s3_region --recursive
  echo `date +%Y-%m-%d-%H:%M:%S`: finish uploading ${scale}g data to s3
  echo "aws s3 ls $s3_path/${scale}g/ --region $s3_region --human-readable"
  aws s3 ls $s3_path/${scale}g/ --region $s3_region --human-readable
  echo `date +%Y-%m-%d-%H:%M:%S`: done
  echo -----------------------------------------------------------
done

cd $old_path
