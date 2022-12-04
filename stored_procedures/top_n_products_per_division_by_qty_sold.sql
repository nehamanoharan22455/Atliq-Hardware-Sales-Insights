CREATE DEFINER=`root`@`localhost` PROCEDURE `top_n_products_per_division_by_qty_sold`(
	in in_fiscal_year int,
    in top_n int)
BEGIN
	with cte1 as 
	(select 
		p.division, 
		p.product,
		sum(s.sold_quantity) as total_sold_quantity	
	from dim_product p
	join fact_sales_monthly s
	on p.product_code = s.product_code
	where fiscal_year = in_fiscal_year
	group by p.product),

		cte2 as (
			select 
				*,
				dense_rank() over(partition by division order by total_sold_quantity desc) as ranking
			from cte1)
	select 
		*
	from cte2
	where ranking <= top_n;
END