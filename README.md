TPC-H是OLAP应用标准的benchmark， 在数据库选型，升级时经常用到。

本程序主要简化了TPC-H的步骤，同时进行了封装，以便能够快速的进行测试。目前的版本支持的数据库有postgresql, mysql, aws redshift。由于aws aurora对于mysql和postgresql的高度兼容性，所以aurora也可以进行测试。对于其他数据库，可能需要修改下文用到的程序代码，并做相应的测试。

主要简化的内容：
1. 数据库的修改删除操作。主要原因是我们的业务场景是数据仓库，数据的同步是大量，并且定时的，一般选取的时候也是深夜，很少有用户来对数据库进行操作。
2. 并发的查询。目前版本还没有考虑。

# 1. 数据准备
## 1.1 生成查询
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

## 1.2 生成数据

第一个参数可以设定需要的scale_factor的列表
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
## 2.1 创建数据库

创建用户tpch, 并创建tpch_1g, tpch_3g, tpch_10g, tpch_30g, tpch_100g五个数据库。注意该命令，会先删除用户和数据库（如果用户或数据库不存在的话，会有报错，但没有关系，可以忽略），然后再创建。
```
./db/postgresql/create_db.sh
./db/redshift/create_db.sh
./db/mysql/create_db.sh
```

## 2.2 创建table

第一个参数可以设定哪些scale_factor的数据库创建新表。下面的命令中将会为tpch_1g, tpch_3g, tpch_10g, tpch_30g创建表。注意该命令会先drop table（如果表不存在的话，会有报错，但没有关系，可以忽略），然后再创建。
```
./db/postgresql/create_table.sh  '1 3 10 30'
./db/redshift/create_table.sh  '1 3 10 30'
./db/mysql/create_table.sh '1 3 10 30'
```

## 2.3 导入数据
第一个参数可以设定哪些scale_factor的数据库需要导入数据。注意要避免重复导入。
```
./db/postgresql/load_data.sh  '1 3'
./db/redshift/load_data.sh  '1 3'
./db/mysql/load_data.sh '1 3'

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

导入10g数据，各个数据库需要的时间如下。其中aurora postgresql
```
 database   |   seconds
------------+------------
 postgresql |      244
 mysql      |        5
 redshift   |       25
```


## 2.4 创建主键和索引
第一个参数可以设定哪些scale_factor的数据库需要创建索引。注意要避免重复导入。由于mysql创建外键非常的缓慢，所以就放弃了外键，转而创建等效的索引。redshift不需要创建主外键。
```
./db/postgresql/create_index.sh  '1 3'
./db/mysql/create_index.sh '1 3'

```

# 3. 测试
## 3.1 简单测试
第一个参数可以设定哪一个scale_factor的数据库将会进行测试。
第二个参数指batch_id, 即1.1中的某一个batch。

```
./db/postgresql/tpch.sh  1 2
./db/redshift/tpch.sh  1 2
./db/mysql/tpch.sh 1 2

```

## 3.2 清除缓存
在每次3.1的测试之前，为了尽量保证查询的内容不被cache，最好清除缓存，但由于环境不同，清除的办法也不相同。

### 3.21 本地环境

本地的环境可以加载postgres和mysql的docker容器。对于redshift只能部署到aws服务器中。

```
docker restart postgresql1  
docker restart mysql1 
```
postgresql1，mysql1是容器名字

### 3.22 aws环境

## 3.3 完整测试

下面以测试本地的postgresql，tpch_1g数据库为例

```
./db/postgresql/tpch.sh  1 1
docker restart postgresql1
./db/postgresql/tpch.sh  1 2
docker restart postgresql1
./db/postgresql/tpch.sh  1 3
docker restart postgresql1
./db/postgresql/tpch.sh  1 

```

**查看测试结果**
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





