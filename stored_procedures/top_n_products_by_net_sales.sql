CREATE DEFINER=`root`@`localhost` PROCEDURE `top_n_products_by_net_sales`(
	in in_market varchar(45),
    in in_fiscal_year int,
    in top_n int
    )
BEGIN
	SELECT 
		product, 
		round(sum(net_sales)/1000000,2) as net_sales_million 
	FROM gdb041.net_sales ns
	where fiscal_year = in_fiscal_year and market = in_market
	group by product
	order by net_sales_million desc
	limit top_n;
END