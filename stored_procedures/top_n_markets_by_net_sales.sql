CREATE DEFINER=`root`@`localhost` PROCEDURE `top_n_markets_by_net_sales`(
	
    in in_fiscal_year int,
    in top_n int)
BEGIN
	SELECT 
		market, 
		round(sum(net_sales)/1000000,2) as net_sales_million 
	FROM gdb041.net_sales
	where fiscal_year = in_fiscal_year 
	group by market
	order by net_sales_million desc
	limit top_n;

END