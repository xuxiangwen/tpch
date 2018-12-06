set enable_result_cache_for_session to off;
-- using 10040 as a seed to the RNG


explain select
	sum(l_extendedprice) / 7.0 as avg_yearly
from
	lineitem,
	part
where
	p_partkey = l_partkey
	and p_brand = 'Brand#23'
	and p_container = 'SM JAR'
   and l_quantity < (
    select
            0.2 * avg(l_quantity)
    from
            lineitem
    where
            l_partkey = p_partkey
   );
