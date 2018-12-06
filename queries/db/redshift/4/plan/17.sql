set enable_result_cache_for_session to off;
-- using 6807 as a seed to the RNG


explain select
	sum(l_extendedprice) / 7.0 as avg_yearly
from
	lineitem,
	part
where
	p_partkey = l_partkey
	and p_brand = 'Brand#35'
	and p_container = 'WRAP DRUM'
   and l_quantity < (
    select
            0.2 * avg(l_quantity)
    from
            lineitem
    where
            l_partkey = p_partkey
   );
