TPC-H是OLAP应用标准的benchmark， 在数据库选型，升级时经常用到。

本程序主要简化了TPC-H的步骤，同时进行了封装，以便能够快速的进行测试。目前的版本支持的数据库有postgresql, mysql, aws redshift。由于aws aurora对于mysql和postgresql的高度兼容性，所以aurora也可以进行测试。对于其他数据库，可能需要修改下文用到的程序代码，并做相应的测试。

主要简化的内容：
1. 数据库的修改删除操作。主要原因是我们的业务场景是数据仓库，数据的同步是大量，并且定时的，一般选取的时候也是深夜，很少有用户来对数据库进行操作。
2. 并发的查询。目前版本还没有考虑。

# 1. 数据准备
## 1.1 配置数据库参数
替换db.conf中的'**REMOVED***'为实际的密码。
```
vim db/mysql/db.conf
vim db/postgresql/db.conf
vim db/redshift/db.conf
```
以db/mysql/db.conf为例。
```
export database=mysql
export instance=local

export db_type=mysql
export db_server=aa00
export db_admin_user=root
export db_admin_password=***REMOVED***
export db_name=mysql
export db_port=3306
export db_user=tpch
export db_password=***REMOVED***

export base_path=~/eipi10/tpch
export data_path=$base_path/data/$db_type
export query_path=$base_path/queries/db/$db_type
```

修改dss.db中的'**REMOVED***'为实际的密码。
```
vim db/mysql/dss.db
vim db/postgresql/dss.db
vim db/redshift/dss.db
```
以db/mysql/db.db。
```
drop database tpch_1g;
drop database tpch_3g;
drop database tpch_10g;
drop database tpch_30g;
drop database tpch_100g;
drop user tpch;

CREATE USER 'tpch'@'%' IDENTIFIED BY '***REMOVED***';

CREATE DATABASE tpch_1g;
CREATE DATABASE tpch_3g;
CREATE DATABASE tpch_10g;
CREATE DATABASE tpch_30g;
CREATE DATABASE tpch_100g;

GRANT ALL ON tpch_1g.* to 'tpch'@'%';
GRANT ALL ON tpch_3g.* to 'tpch'@'%';
GRANT ALL ON tpch_10g.* to 'tpch'@'%';
GRANT ALL ON tpch_30g.* to 'tpch'@'%';
GRANT ALL ON tpch_100g.* to 'tpch'@'%';
-- GRANT LOAD FROM S3 ON *.* TO 'tpch'@'%';

show databases;
show grants for tpch;
```

## 1.2 生成查询
生成多个batch的sql查询语句。第一个参数是指batch的数量。一般在性能测试中，会进行多batch的测试，这样可以保证结果的稳定性（每个batch中，同编号的sql的一些过滤条件不同，这样可以减少cache的命中）。测试之前，我们预先实现生成了每个batch的查询，这样更加方便来进行比较和分析。

```
./qgen.sh 10
```

**检查生成的查询**  
每个batch中会有22个sql。

```
ll ./queries/db/postgresql/2 
ll ./queries/db/redshift/2  
ll ./queries/db/mysql/2 
```

生成的sql文件如下：

```
total 92
-rw-rw-r--. 1 grid grid  575 Dec  5 11:36 10.sql
-rw-rw-r--. 1 grid grid  556 Dec  5 11:36 11.sql
-rw-rw-r--. 1 grid grid  642 Dec  5 11:36 12.sql
-rw-rw-r--. 1 grid grid  395 Dec  5 11:36 13.sql
-rw-rw-r--. 1 grid grid  377 Dec  5 11:36 14.sql
-rw-rw-r--. 1 grid grid  576 Dec  5 11:36 15.sql
-rw-rw-r--. 1 grid grid  532 Dec  5 11:36 16.sql
-rw-rw-r--. 1 grid grid  393 Dec  5 11:36 17.sql
-rw-rw-r--. 1 grid grid  499 Dec  5 11:36 18.sql
-rw-rw-r--. 1 grid grid 1023 Dec  5 11:36 19.sql
-rw-rw-r--. 1 grid grid  579 Dec  5 11:36 1.sql
-rw-rw-r--. 1 grid grid  805 Dec  5 11:36 20.sql
-rw-rw-r--. 1 grid grid  712 Dec  5 11:36 21.sql
-rw-rw-r--. 1 grid grid  708 Dec  5 11:36 22.sql
-rw-rw-r--. 1 grid grid  745 Dec  5 11:36 2.sql
-rw-rw-r--. 1 grid grid  460 Dec  5 11:36 3.sql
-rw-rw-r--. 1 grid grid  405 Dec  5 11:36 4.sql
-rw-rw-r--. 1 grid grid  547 Dec  5 11:36 5.sql
-rw-rw-r--. 1 grid grid  295 Dec  5 11:36 6.sql
-rw-rw-r--. 1 grid grid  859 Dec  5 11:36 7.sql
-rw-rw-r--. 1 grid grid  843 Dec  5 11:36 8.sql
-rw-rw-r--. 1 grid grid  654 Dec  5 11:36 9.sql
drwxrwxr-x. 2 grid grid 4096 Dec  5 11:36 plan
```
其中plan目录也包含了22个sql文件，只是这些sql文件包含了执行计划的部分，便于我们后期的分析。

**检查查询条件**  
希望每个batch生成的sql的filter都不完全相同。这样可以更加保证在性能测试时，更加符合实际的场景。

```
./check_query.sh
```

## 1.3 生成数据

对于redshift的数据，我们采用了lzo压缩方式，所以需要用如下命令安装lzop。如果不使用redshift，可以忽略这一步。
```
yum install -y lzop
```

第一个参数可以设定需要的scale_factor的列表。
```
./dbgen.sh '1 3 10'
```
程序中会生成postgresql, mysql, redshift的数据，如果需要生成其他数据库的数据，可以对dgben.sh里面的内容做一些修改。这三个数据库的数据，其中mysql是最先生成的，postgresql会在mysql数据的基础上删除每行最后一个"|"，而redshift会在postgresql的基础上，压缩成lzo文件。


**检查生成的数据**  
```
ll -h ./data/mysql/1g
ll -h ./data/postgresql/1g
ll -h ./data/redshift/1g
```

生成的数据文件如下：
```
total 1.1G
-rw-rw-r--. 1 grid grid  24M Dec  5 15:05 customer.tbl
-rw-rw-r--. 1 grid grid 725M Dec  5 15:05 lineitem.tbl
-rw-rw-r--. 1 grid grid 2.2K Dec  5 15:05 nation.tbl
-rw-rw-r--. 1 grid grid 164M Dec  5 15:05 orders.tbl
-rw-rw-r--. 1 grid grid 114M Dec  5 15:05 partsupp.tbl
-rw-rw-r--. 1 grid grid  24M Dec  5 15:05 part.tbl
-rw-rw-r--. 1 grid grid  389 Dec  5 15:05 region.tbl
-rw-rw-r--. 1 grid grid 1.4M Dec  5 15:05 supplier.tbl
```


**上传数据到s3**  
仅限于aws redshift数据。由于redshift只支持从s3上导入数据。
```
./db/redshift/upload_s3.sh  '1 3 10 30'
```

# 2. 数据库初始化
## 2.1 参数配置

进入数据库的具体目录。

```
cd ./db/postgresql
cd ./db/redshift
cd ./db/mysql
```

执行以下脚本来生成配置文件tpch.conf。需要根据我们的实际情况修改。 一般需要修改的是db开头的参数，还有就是base_path，它就是tpch目录在你的机器上的位置。

```
cat << EOF > tpch.conf
export database=postgresql
export instance=local

export db_type=postgresql
export db_server=localhost
export db_admin_user=postgres
export db_admin_password=12345678
export db_name=postgres
export db_port=5432
export db_user=tpch
export db_password=12345678

export base_path=~/eipi10/tpch
export data_path=\$base_path/data/\$db_type
export query_path=\$base_path/queries/db/\$db_type
EOF
```

## 2.2 创建数据库

创建用户tpch, 并创建tpch_1g, tpch_3g, tpch_10g, tpch_30g, tpch_100g五个数据库。注意该命令，会先删除用户和数据库（如果用户或数据库不存在的话，会有报错，但没有关系，可以忽略），然后再创建。
```
./db/postgresql/create_db.sh
./db/redshift/create_db.sh
./db/mysql/create_db.sh
```

## 2.3 创建table

第一个参数可以设定哪些scale_factor的数据库创建新表。下面的命令中将会为tpch_1g, tpch_3g, tpch_10g, tpch_30g创建表。注意该命令会先drop table（如果表不存在的话，会有报错，但没有关系，可以忽略），然后再创建。
```
./db/postgresql/create_table.sh  '1 3 10 30'
./db/redshift/create_table.sh  '1 3 10 30'
./db/mysql/create_table.sh '1 3 10 30'
```

**redshift优化表结构**  
由于redshift中没有索引，但可以通过dist key, sort key进行性能优化。下面命令中dss.ddl.opt是新的创建table语句，位于./db/redshift目录。在后文中有详细分析。
```

./db/redshift/create_table.sh  '1 3 10 30' dss.ddl.opt
```

## 2.4 导入数据
第一个参数可以设定哪些scale_factor的数据库需要导入数据。注意要避免重复导入。
```
./db/postgresql/load_data.sh  '1 3 10'
./db/redshift/load_data.sh  '1 3 10'
./db/mysql/load_data.sh '1 3 10'

```

以下是导入1g数据后，各个表的数据量。
```
 table_name |   cnt
------------+---------
 customer   |  150000
 region     |       5
 nation     |      25
 supplier   |   10000
 part       |  200000
 partsupp   |  800000
 orders     | 1500000
 lineitem   | 6001215
```




## 2.5 创建主键和索引
第一个参数可以设定哪些scale_factor的数据库需要创建索引。注意要避免重复导入。由于mysql创建外键非常的缓慢，所以就放弃了外键，转而创建等效的索引。由于redshift中要保证数据的唯一性相对困难，所以在redshift没有创建主外键。
```
./db/postgresql/create_index.sh  '1 3'
./db/mysql/create_index.sh '1 3'

```

# 3. 测试
## 3.1 简单测试
```
-s: 指定一个scale_factor。
-b: 指定一个batch_id, 即1.1中的某一个batch。
```
```
./db/postgresql/tpch.sh  -s 1 -b 2
./db/redshift/tpch.sh -s 1 -b 2
./db/mysql/tpch.sh -s 1 -b 2

```

## 3.2 清除缓存后再测试
tpch.sh还有一个参数，如果设置，每次sql运行前，会尝试尽量清除或不使用缓存。

```
-c: clear cache
```

- mysql：reset当前的cache。
```
RESET QUERY CACHE;
```
- postgresql: 没有特别设置。由于每个batch的sql并不完全相同，能够减少对cache的使用。
- redshift: 在每个sql执行的时候，会执行如下语句。
```
set enable_result_cache_for_session to off;
```


```
./db/postgresql/tpch.sh  -s 1 -b 2 -c
./db/redshift/tpch.sh  -s 1 -b 2 -c
./db/mysql/tpch.sh -s 1 -b 2 -c
```



## 3.3 完整测试
首先进入要测试数据库的相应目录。
```
cd db/redshift
cd db/mysql
cd db/postgresql
```
然后运行如下语句。
```
./tpch.sh -s 1  -b 1 -c
./tpch.sh -s 1  -b 2 -c
./tpch.sh -s 1  -b 3 -c
./tpch.sh -s 1  -b 4 -c
./tpch.sh -s 3  -b 1 -c
./tpch.sh -s 3  -b 2 -c
./tpch.sh -s 3  -b 3 -c
./tpch.sh -s 3  -b 4 -c
./tpch.sh -s 10 -b 1 -c
./tpch.sh -s 10 -b 2 -c
./tpch.sh -s 10 -b 3 -c
./tpch.sh -s 10 -b 4 -c
./tpch.sh -s 30 -b 1 -c
./tpch.sh -s 30 -b 2 -c
./tpch.sh -s 30 -b 3 -c
./tpch.sh -s 30 -b 4 -c


#only run explain plan
./tpch.sh -s 1  -b 5 -c -e 
./tpch.sh -s 3  -b 5 -c -e
./tpch.sh -s 10 -b 5 -c -e
./tpch.sh -s 30 -b 5 -c -e
```

## 3.4 查看测试结果
```
cat ./db/postgresql/tpch.csv
cat ./db/mysql/tpch.csv
cat ./db/redshift/tpch.csv
```

文件里面的数据如下，可以导入到其他分析工具（比如excel）中进行统计分析。
```shell
instance,database,test_time,db_name,batch_id,query_id,query_time
local,postgresql,2018-12-05-23:17:38,tpch_1g,4,1,2.780
local,postgresql,2018-12-05-23:17:38,tpch_1g,4,2,0.458
local,postgresql,2018-12-05-23:17:38,tpch_1g,4,3,0.548
local,postgresql,2018-12-05-23:17:38,tpch_1g,4,4,0.266
local,postgresql,2018-12-05-23:17:38,tpch_1g,4,5,0.585
local,postgresql,2018-12-05-23:17:38,tpch_1g,4,6,0.539
local,postgresql,2018-12-05-23:17:38,tpch_1g,4,7,0.679

```

# 4 结果分析
## 4.1 测试环境
比较了redshift, aurora-mysql（下面直接称mysql）, aurora-postgresql(下面直接称postgresql)在成本相似硬件下的性能。

reshift的硬件如下，我们选用了1个节点和2个节点进行测试。 

| 节点大小        | vCPU | ECU | RAM (GiB) | 每节点的切片数 | 每节点的存储容量        |
|-------------|------|-----|-----------|---------|-----------------|
| dc2.large   | 2    | 7   | 15.25     | 2       | 160 GB NVMe-SSD |

mysql, postgresql的硬件配置如下。

| 实例类           | vCPU1 | ECU2 | 内存3(GiB) | 仅限 VPC4 | EBS 优化5 |
|---------------|-------|------|----------|---------|---------|
| db.r4.large   | 2     | 7    | 15.25    | 是       | 是       |
| db.r4.xlarge  | 4     | 13.5 | 30.5     | 是       | 是       |

**成本比较**

- dc2.large的成本和 db.r4.large相当  
- 2*dc2.large的成本和 db.r4.xlarge相当   

## 4.2 分析结果

- redshift在3g及3g以上数据量情况下，性能比mysql和postgresql好很多。而在1g的数据量下，mysql和postgresql大多数情况下更加有优势。

实际在db.r4.large的配置下，mysql和postgresql无法完成10g数据量的测试。

| db_size | instance    | database  | 1     | 2    | 3    | 4    | 5    | 6    | 7    | 8    | 9     | 10   | 11   |
|---------|-------------|-----------|-------|------|------|------|------|------|------|------|-------|------|------|
| 1g      | db.r4.large | aurora-my | 14.99 | 0.26 | 1.71 | 0.53 | 1.53 | 2.25 | 1.03 | 0.40 | 2.92  | 1.14 | 0.31 |
|         |             | aurora-pg | 10.82 | 0.66 | 0.87 | 0.37 | 0.66 | 0.77 | 0.75 | 0.88 | 5.16  | 1.88 | 0.20 |
|         | dc2.large   | redshift  | 1.85  | 3.07 | 1.44 | 1.93 | 1.86 | 1.99 | 2.73 | 1.91 | 3.63  | 0.80 | 1.50 |
| 3g      | db.r4.large | aurora-my | 44.83 | 0.51 | 5.50 | 1.71 | 4.94 | 6.70 | 3.01 | 1.25 | 9.23  | 6.00 | 1.24 |
|         |             | aurora-pg | 32.52 | 2.00 | 7.32 | 1.35 | 1.97 | 2.68 | 4.91 | 2.66 | 15.54 | 5.82 | 0.53 |
|         | dc2.large   | redshift  | 5.51  | 1.21 | 2.19 | 3.74 | 1.48 | 1.19 | 1.99 | 2.81 | 2.84  | 2.34 | 0.36 |


| db_size | instance    | database  | 12   | 13    | 14   | 15   | 16   | 17   | 18    | 19   | 20    | 21    | 22   |
|---------|-------------|-----------|------|-------|------|------|------|------|-------|------|-------|-------|------|
| 1g      | db.r4.large | aurora-my | 2.54 | 4.78  | 0.81 | 2.21 | 0.28 | 0.55 | 2.92  | 0.20 | 21.83 | 17.59 | 0.34 |
|         |             | aurora-pg | 1.70 | 1.79  | 0.31 | 1.16 | 1.08 | 0.29 | 4.34  | 0.23 | 2.37  | 1.96  | 0.30 |
|         | dc2.large   | redshift  | 2.89 | 0.93  | 1.13 | 1.27 | 0.28 | 4.78 | 1.92  | 1.63 | 3.18  | 2.44  | 0.29 |
| 3g      | db.r4.large | aurora-my | 7.95 | 15.97 | 2.47 | 6.90 | 0.98 | 1.77 | 8.74  | 0.54 | 69.43 | 53.71 | 0.70 |
|         |             | aurora-pg | 5.19 | 5.49  | 1.50 | 5.03 | 3.22 | 0.57 | 13.64 | 0.50 | 8.60  | 5.83  | 0.78 |
|         | dc2.large   | redshift  | 2.25 | 3.13  | 1.10 | 1.32 | 0.70 | 1.63 | 5.81  | 3.29 | 2.99  | 5.06  | 0.75 |

- mysql和postgresql在db.r4.large的硬件配置下，由于太慢，无法完成10g数据量测试。而在db.r4.xlarge的配置下，可以完成查询。而在监控端，发现其实cpu占用率不是很高，这说明内存的增加对于数据性能的提高非常关键。

| db_size | instance     | database  | 1      | 2     | 3     | 4    | 5     | 6     | 7     | 8    | 9     | 10    | 11   |
|---------|--------------|-----------|--------|-------|-------|------|-------|-------|-------|------|-------|-------|------|
| 10g     | db.r4.xlarge | aurora-my | 142.83 | 1.40  | 18.67 | 5.50 | 16.93 | 20.66 | 10.15 | 4.28 | 30.97 | 24.28 | 4.92 |
|         |              | aurora-pg | 106.12 | 10.80 | 23.09 | 4.36 | 7.26  | 9.02  | 17.47 | 8.71 | 65.11 | 20.07 | 1.60 |
| 1g      | db.r4.large  | aurora-my | 14.99  | 0.26  | 1.71  | 0.53 | 1.53  | 2.25  | 1.03  | 0.40 | 2.92  | 1.14  | 0.31 |
|         |              | aurora-pg | 10.82  | 0.66  | 0.87  | 0.37 | 0.66  | 0.77  | 0.75  | 0.88 | 5.16  | 1.88  | 0.20 |
|         | db.r4.xlarge | aurora-my | 14.41  | 0.23  | 1.64  | 0.51 | 1.46  | 2.06  | 1.11  | 0.41 | 2.76  | 1.03  | 0.46 |
|         |              | aurora-pg | 10.54  | 0.74  | 0.83  | 0.38 | 0.55  | 0.73  | 0.68  | 0.72 | 5.34  | 1.66  | 0.20 |
| 3g      | db.r4.large  | aurora-my | 44.83  | 0.51  | 5.50  | 1.71 | 4.94  | 6.70  | 3.01  | 1.25 | 9.23  | 6.00  | 1.24 |
|         |              | aurora-pg | 32.52  | 2.00  | 7.32  | 1.35 | 1.97  | 2.68  | 4.91  | 2.66 | 15.54 | 5.82  | 0.53 |
|         | db.r4.xlarge | aurora-my | 43.06  | 0.48  | 5.15  | 1.61 | 4.60  | 6.22  | 2.89  | 1.17 | 8.63  | 5.73  | 1.17 |
|         |              | aurora-pg | 31.73  | 1.92  | 6.62  | 1.33 | 1.80  | 2.53  | 4.59  | 2.38 | 16.53 | 5.59  | 0.54 |

| db_size | instance     | database  | 12    | 13    | 14   | 15    | 16    | 17   | 18    | 19   | 20     | 21     | 22   |
|---------|--------------|-----------|-------|-------|------|-------|-------|------|-------|------|--------|--------|------|
| 10g     | db.r4.xlarge | aurora-my | 24.10 | 54.65 | 6.59 | 22.10 | 2.98  | 5.65 | 28.00 | 1.47 | 235.20 | 173.44 | 1.96 |
|         |              | aurora-pg | 16.63 | 18.35 | 5.49 | 17.53 | 10.45 | 1.88 | 46.28 | 1.52 | 36.31  | 43.33  | 2.27 |
| 1g      | db.r4.large  | aurora-my | 2.54  | 4.78  | 0.81 | 2.21  | 0.28  | 0.55 | 2.92  | 0.20 | 21.83  | 17.59  | 0.34 |
|         |              | aurora-pg | 1.70  | 1.79  | 0.31 | 1.16  | 1.08  | 0.29 | 4.34  | 0.23 | 2.37   | 1.96   | 0.30 |
|         | db.r4.xlarge | aurora-my | 2.42  | 4.56  | 0.83 | 2.29  | 0.28  | 0.55 | 2.78  | 0.21 | 20.72  | 16.81  | 0.26 |
|         |              | aurora-pg | 1.65  | 1.71  | 0.36 | 1.10  | 1.04  | 0.29 | 4.20  | 0.22 | 2.21   | 1.86   | 0.29 |
| 3g      | db.r4.large  | aurora-my | 7.95  | 15.97 | 2.47 | 6.90  | 0.98  | 1.77 | 8.74  | 0.54 | 69.43  | 53.71  | 0.70 |
|         |              | aurora-pg | 5.19  | 5.49  | 1.50 | 5.03  | 3.22  | 0.57 | 13.64 | 0.50 | 8.60   | 5.83   | 0.78 |
|         | db.r4.xlarge | aurora-my | 7.24  | 14.84 | 2.32 | 6.43  | 0.95  | 1.66 | 8.36  | 0.48 | 66.15  | 51.21  | 0.62 |
|         |              | aurora-pg | 5.07  | 4.97  | 1.45 | 4.78  | 3.05  | 0.58 | 12.82 | 0.47 | 8.35   | 5.59   | 0.69 |

然后从上面两个表来看，升级到db.r4.xlarge（cpu和内存都翻倍），10g数据可以跑出来了。但在1g和3g的数据量下，性能几乎没有提高，这说明在内存足够的情况下，由于sql中计算的工作很少，所以多核cpu没有更多的优势。

- 从10g以上数据量来看，redshift具有更加明显的优势。即使单个dc2.large也比db.r4.xlarge的性能好很多。而两个dc2.large节点，在成本相同的情况下，性能比db.r4.xlarge至少好5-10倍。

| db_size | instance     | database  | 1      | 2     | 3     | 4     | 5     | 6     | 7     | 8    | 9     | 10    | 11   |
|---------|--------------|-----------|--------|-------|-------|-------|-------|-------|-------|------|-------|-------|------|
| 10g     | 2*dc2.large  | redshift  | 3.07   | 2.41  | 1.27  | 4.11  | 1.33  | 0.54  | 1.52  | 2.16 | 2.47  | 1.62  | 0.25 |
|         | db.r4.xlarge | aurora-my | 142.83 | 1.40  | 18.67 | 5.50  | 16.93 | 20.66 | 10.15 | 4.28 | 30.97 | 24.28 | 4.92 |
|         |              | aurora-pg | 106.12 | 10.80 | 23.09 | 4.36  | 7.26  | 9.02  | 17.47 | 8.71 | 65.11 | 20.07 | 1.60 |
|         | dc2.large    | redshift  | 17.99  | 2.85  | 7.04  | 14.34 | 5.23  | 3.87  | 6.86  | 7.20 | 9.86  | 8.19  | 1.17 |

| db_size | instance     | database  | 12    | 13    | 14   | 15    | 16    | 17   | 18    | 19   | 20     | 21     | 22   |
|---------|--------------|-----------|-------|-------|------|-------|-------|------|-------|------|--------|--------|------|
| 10g     | 2*dc2.large  | redshift  | 0.77  | 2.89  | 0.60 | 0.86  | 0.55  | 2.20 | 7.62  | 2.03 | 2.20   | 3.40   | 0.74 |
|         | db.r4.xlarge | aurora-my | 24.10 | 54.65 | 6.59 | 22.10 | 2.98  | 5.65 | 28.00 | 1.47 | 235.20 | 173.44 | 1.96 |
|         |              | aurora-pg | 16.63 | 18.35 | 5.49 | 17.53 | 10.45 | 1.88 | 46.28 | 1.52 | 36.31  | 43.33  | 2.27 |
|         | dc2.large    | redshift  | 5.06  | 11.40 | 3.54 | 4.24  | 2.50  | 7.44 | 19.23 | 6.49 | 10.41  | 17.64  | 2.69 |

- 从上面的表格可以发现，redshift从一个节点升级到两个节点，性能提高4倍。这的确有些出于意料。而且在所有数据量的情况下，都是如此。

| db_size | instance    | database | 1     | 2    | 3     | 4     | 5     | 6     | 7     | 8     | 9     | 10    | 11   |
|---------|-------------|----------|-------|------|-------|-------|-------|-------|-------|-------|-------|-------|------|
| 10g     | 2*dc2.large | redshift | 3.07  | 2.41 | 1.27  | 4.11  | 1.33  | 0.54  | 1.52  | 2.16  | 2.47  | 1.62  | 0.25 |
|         | dc2.large   | redshift | 17.99 | 2.85 | 7.04  | 14.34 | 5.23  | 3.87  | 6.86  | 7.20  | 9.86  | 8.19  | 1.17 |
| 1g      | 2*dc2.large | redshift | 0.34  | 2.48 | 0.91  | 0.95  | 1.10  | 2.19  | 2.03  | 1.32  | 2.11  | 0.23  | 1.31 |
|         | dc2.large   | redshift | 1.85  | 3.07 | 1.44  | 1.93  | 1.86  | 1.99  | 2.73  | 1.91  | 3.63  | 0.80  | 1.50 |
| 30g     | 2*dc2.large | redshift | 9.11  | 2.53 | 3.79  | 16.34 | 3.48  | 1.58  | 4.42  | 2.81  | 7.39  | 5.02  | 0.96 |
|         | dc2.large   | redshift | 53.85 | 6.11 | 21.35 | 48.78 | 14.64 | 11.61 | 19.73 | 15.65 | 31.45 | 23.53 | 3.85 |
| 3g      | 2*dc2.large | redshift | 0.93  | 2.49 | 0.44  | 1.09  | 0.41  | 0.18  | 0.46  | 1.42  | 0.76  | 0.54  | 0.12 |
|         | dc2.large   | redshift | 5.51  | 1.21 | 2.19  | 3.74  | 1.48  | 1.19  | 1.99  | 2.81  | 2.84  | 2.34  | 0.36 |

| db_size | instance    | database | 12    | 13    | 14    | 15    | 16   | 17    | 18    | 19    | 20    | 21    | 22    |
|---------|-------------|----------|-------|-------|-------|-------|------|-------|-------|-------|-------|-------|-------|
| 10g     | 2*dc2.large | redshift | 0.77  | 2.89  | 0.60  | 0.86  | 0.55 | 2.20  | 7.62  | 2.03  | 2.20  | 3.40  | 0.74  |
|         | dc2.large   | redshift | 5.06  | 11.40 | 3.54  | 4.24  | 2.50 | 7.44  | 19.23 | 6.49  | 10.41 | 17.64 | 2.69  |
| 1g      | 2*dc2.large | redshift | 3.49  | 0.30  | 0.83  | 1.93  | 0.14 | 4.38  | 0.61  | 1.01  | 2.27  | 1.05  | 0.14  |
|         | dc2.large   | redshift | 2.89  | 0.93  | 1.13  | 1.27  | 0.28 | 4.78  | 1.92  | 1.63  | 3.18  | 2.44  | 0.29  |
| 30g     | 2*dc2.large | redshift | 3.12  | 9.60  | 1.80  | 2.71  | 1.69 | 2.05  | 26.57 | 4.44  | 7.38  | 9.84  | 2.48  |
|         | dc2.large   | redshift | 16.42 | 42.19 | 10.56 | 12.14 | 7.50 | 16.46 | 60.59 | 18.17 | 32.03 | 51.27 | 10.55 |
| 3g      | 2*dc2.large | redshift | 1.05  | 0.83  | 0.20  | 0.38  | 0.20 | 0.27  | 1.78  | 2.08  | 0.59  | 1.05  | 0.26  |
|         | dc2.large   | redshift | 2.25  | 3.13  | 1.10  | 1.32  | 0.70 | 1.63  | 5.81  | 3.29  | 2.99  | 5.06  | 0.75  |

- 尝试使用dist key, sort key优化了redshift的表结构，但测试表明没有明显性能提升，而且有提升，有降低。这有可能是dist key, sort key设置的不合理，没有仔细分析执行计划。
 

| db_size | instance  | database       | 1     | 2    | 3     | 4     | 5     | 6     | 7     | 8     | 9     | 10    | 11   |
|---------|-----------|----------------|-------|------|-------|-------|-------|-------|-------|-------|-------|-------|------|
| 10g     | dc2.large | redshift       | 17.99 | 2.85 | 7.04  | 14.34 | 5.23  | 3.87  | 6.86  | 7.20  | 9.86  | 8.19  | 1.17 |
|         |           | redshift_opd   | 18.06 | 3.17 | 6.14  | 13.57 | 5.52  | 2.56  | 13.88 | 5.99  | 9.16  | 9.10  | 1.45 |
|         |           | redshift_opd_1 | 17.95 | 4.40 | 7.04  | 13.60 | 5.35  | 4.00  | 16.72 | 5.42  | 8.94  | 9.99  | 1.40 |
| 1g      | dc2.large | redshift       | 1.85  | 3.07 | 1.44  | 1.93  | 1.86  | 1.99  | 2.73  | 1.91  | 3.63  | 0.80  | 1.50 |
|         |           | redshift_opd   | 1.85  | 3.75 | 1.39  | 1.46  | 1.95  | 1.93  | 3.53  | 2.03  | 0.93  | 0.87  | 1.52 |
|         |           | redshift_opd_1 | 1.88  | 1.71 | 0.73  | 1.42  | 1.27  | 2.05  | 3.55  | 1.94  | 1.58  | 0.90  | 0.19 |
| 30g     | dc2.large | redshift       | 53.85 | 6.11 | 21.35 | 48.78 | 14.64 | 11.61 | 19.73 | 15.65 | 31.45 | 23.53 | 3.85 |
|         |           | redshift_opd   | 54.97 | 6.65 | 18.17 | 47.00 | 17.63 | 5.96  | 21.81 | 17.97 | 32.43 | 24.94 | 4.07 |
|         |           | redshift_opd_1 | 53.78 | 6.78 | 21.12 | 47.38 | 16.83 | 11.90 | 24.86 | 15.84 | 31.02 | 33.31 | 4.58 |
| 3g      | dc2.large | redshift       | 5.51  | 1.21 | 2.19  | 3.74  | 1.48  | 1.19  | 1.99  | 2.81  | 2.84  | 2.34  | 0.36 |
|         |           | redshift_opd   | 5.46  | 0.48 | 1.96  | 3.33  | 1.60  | 0.93  | 6.36  | 1.50  | 2.89  | 2.56  | 0.47 |
|         |           | redshift_opd_1 | 5.36  | 1.21 | 2.11  | 3.26  | 1.61  | 1.23  | 6.60  | 1.34  | 3.39  | 2.77  | 0.46 |

| db_size | instance  | database       | 12    | 13    | 14    | 15    | 16   | 17    | 18    | 19    | 20    | 21    | 22    |
|---------|-----------|----------------|-------|-------|-------|-------|------|-------|-------|-------|-------|-------|-------|
| 10g     | dc2.large | redshift       | 5.06  | 11.40 | 3.54  | 4.24  | 2.50 | 7.44  | 19.23 | 6.49  | 10.41 | 17.64 | 2.69  |
|         |           | redshift_opd   | 4.32  | 10.21 | 1.92  | 2.14  | 2.29 | 7.25  | 16.26 | 6.50  | 8.17  | 17.75 | 3.34  |
|         |           | redshift_opd_1 | 5.81  | 11.20 | 3.70  | 3.99  | 2.55 | 4.62  | 16.84 | 7.97  | 9.76  | 16.99 | 3.55  |
| 1g      | dc2.large | redshift       | 2.89  | 0.93  | 1.13  | 1.27  | 0.28 | 4.78  | 1.92  | 1.63  | 3.18  | 2.44  | 0.29  |
|         |           | redshift_opd   | 2.83  | 0.93  | 1.10  | 1.23  | 0.25 | 4.68  | 1.58  | 0.62  | 3.07  | 2.62  | 0.34  |
|         |           | redshift_opd_1 | 2.84  | 0.93  | 1.17  | 1.32  | 0.28 | 0.54  | 1.63  | 1.48  | 1.77  | 1.92  | 0.34  |
| 30g     | dc2.large | redshift       | 16.42 | 42.19 | 10.56 | 12.14 | 7.50 | 16.46 | 60.59 | 18.17 | 32.03 | 51.27 | 10.55 |
|         |           | redshift_opd   | 9.37  | 33.90 | 4.51  | 5.74  | 6.61 | 16.10 | 79.70 | 17.69 | 24.97 | 53.96 | 10.60 |
|         |           | redshift_opd_1 | 15.45 | 42.52 | 11.06 | 11.53 | 7.52 | 13.93 | 80.91 | 18.36 | 28.70 | 50.77 | 11.27 |
| 3g      | dc2.large | redshift       | 2.25  | 3.13  | 1.10  | 1.32  | 0.70 | 1.63  | 5.81  | 3.29  | 2.99  | 5.06  | 0.75  |
|         |           | redshift_opd   | 2.12  | 2.87  | 0.82  | 1.00  | 0.66 | 1.64  | 4.53  | 1.75  | 2.68  | 5.42  | 0.81  |
|         |           | redshift_opd_1 | 1.51  | 3.18  | 1.88  | 1.29  | 0.70 | 1.47  | 4.56  | 2.58  | 2.92  | 5.15  | 0.78  |

## 4.3 总结

根据上述的测试结果，如果就redshfit, mysql和postgresql三者比较，对于OLAP应用，你可以这样选择。

- 1g：mysql或postgresql
- 3g：redshift更好
- 10g及以上: 必须redshift


# 备注
## A. 数据加载速度

从结果上看，redshift的加载速度无疑是最快的。mysql有些过慢了。

| data volume | database   | instance  | load_data (minute) | create_index (minute) | total (minute) |
|-------------|------------|-----------|--------------------|-----------------------|----------------|
| 1g          | mysql      | r4.large  | 2.8                | 3.8                   | 6.6            |
| 3g          | mysql      | r4.large  | 8.3                | 13.9                  | 22.2           |
| 10g         | mysql      | r4.large  | 28                 | 72                    | 100            |
| 1g          | postgresql | r4.large  | 0.9                | 0.8                   | 1.7            |
| 3g          | postgresql | r4.large  | 2.6                | 2.5                   | 5.1            |
| 10g         | postgresql | r4.large  | 8.4                | 12.1                  | 20.5           |
| 1g          | redshift   | dc2.large | 4.9                | 0                     | 4.9            |
| 3g          | redshift   | dc2.large | 2.4                | 0                     | 2.4            |
| 10g         | redshift   | dc2.large | 6.9                | 0                     | 6.9            |
| 30g         | redshift   | dc2.large | 18.5               | 0                     | 18.5           |

