CREATE DEFINER=`root`@`localhost` PROCEDURE `get_market_badge`(
	in in_fiscal_year year, 
    in in_market_name varchar(45),
    out out_badge varchar(45))
BEGIN
	declare qty int default 0;
    #set default market as India
    if in_market_name = "" then
		set in_market_name = "India";
	end if;
    #get total sales for given fiscal year and maket
	select
		sum(sold_quantity) as total_sold_qty into qty
	from 
		dim_customer c
	join
		fact_sales_monthly s
	on c.customer_code = s.customer_code
	where 
		get_fiscal_year(date) = in_fiscal_year and 
        market = in_market_name
	group by c.market;
    
    #assign badge
    if qty > 5000000 then
		set out_badge = "Gold";
	else
		set out_badge = "Silver";
	end if;
END