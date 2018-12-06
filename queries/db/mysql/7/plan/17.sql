-- using 21527 as a seed to the RNG


explain select
	sum(l_extendedprice) / 7.0 as avg_yearly
from
	lineitem,
	part
where
	p_partkey = l_partkey
	and p_brand = 'Brand#44'
	and p_container = 'WRAP PACK'
   and l_quantity < (
    select
            0.2 * avg(l_quantity)
    from
            lineitem
    where
            l_partkey = p_partkey
   );
