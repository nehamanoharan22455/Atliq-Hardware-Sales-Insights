CREATE DEFINER=`root`@`localhost` PROCEDURE `get_monthly_gross_sales`(
	c_code_list text)
BEGIN
	select 
		s.date, 
		round(sum(s.sold_quantity*g.gross_price),2) as total_gross_price
	from 
		fact_sales_monthly s
	join 
		fact_gross_price g
	on 
		s.product_code = g.product_code and 
		g.fiscal_year = get_fiscal_year(s.date)
	where find_in_set(s.customer_code, c_code_list)
	group by s.date 
	order by s.date;
END