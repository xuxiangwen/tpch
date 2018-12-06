set enable_result_cache_for_session to off;
-- using 12237 as a seed to the RNG


explain select
	c_count,
	count(*) as custdist
from
	(
		select
			c_custkey,
			count(o_orderkey) as c_count
		from
			customer left outer join orders on
				c_custkey = o_custkey
				and o_comment not like '%special%packages%'
		group by
			c_custkey
	) as c_orders 
group by
	c_count
order by
	custdist desc,
	c_count desc
LIMIT 1;
