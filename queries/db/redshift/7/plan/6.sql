set enable_result_cache_for_session to off;
-- using 28172 as a seed to the RNG


explain select
	sum(l_extendedprice * l_discount) as revenue
from
	lineitem
where
	l_shipdate >= date '1994-01-01'
	and l_shipdate < date '1994-01-01' + interval '1 year'
	and l_discount between 0.09 - 0.01 and 0.09 + 0.01
	and l_quantity < 24
LIMIT 1;
