CREATE DEFINER=`root`@`localhost` PROCEDURE `top_n_customer_by_net_sales`(
	in in_market varchar(40),
    in in_fiscal_year int,
    in top_n int)
BEGIN
	SELECT 
		c.customer, 
        c.market,
		round(sum(net_sales)/1000000,2) as net_sales_million 
	FROM gdb041.net_sales ns
	join dim_customer c
	on c.customer_code = ns.customer_code
	where fiscal_year = in_fiscal_year and
		c.market = in_market
	group by customer
	order by net_sales_million desc
	limit top_n;
END