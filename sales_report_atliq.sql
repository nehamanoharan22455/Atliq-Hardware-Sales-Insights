-- generate report of individual product sales
-- (aggregated on monthly basis on product_code level)
-- for Croma India customer for FY = 2021. Fiscal year starts from Sept

-- retrieving customer_code for Croma India
SELECT customer_code FROM gdb041.dim_customer
where customer like '%croma%' and market = "india";
 
-- fiscal year is calculated using user defined function get_fiscal_year
select f.date, f.product_code, p.product, p.variant, f.sold_quantity, g.gross_price,
	round(f.sold_quantity * g.gross_price,2) as gross_total_price
from 
	fact_sales_monthly f
join dim_product p
using (product_code)
join fact_gross_price g
on	g.product_code = f.product_code and
g.fiscal_year = get_fiscal_year(f.date)
where 
	customer_code = 90002002 and 
    get_fiscal_year(date) = 2021
order by date;

-- Report for 4th quarter
select f.date, f.product_code, p.product, p.variant, f.sold_quantity, g.gross_price,
	round(f.sold_quantity * g.gross_price,2) as gross_total_price
from 
	fact_sales_monthly f
join dim_product p
using (product_code)
join fact_gross_price g
on	g.product_code = f.product_code and
g.fiscal_year = get_fiscal_year(f.date)	
where 
	customer_code = 90002002 and 
    get_fiscal_year(date) = 2021 and
    get_fiscal_quarter(date) = "q4"
order by date;

-- aggregate monthly report for Croma India
-- fields to be included in the report
-- 1. Month
-- 2. Gross sales for that month
select 
	s.date, 
	round(sum(s.sold_quantity*g.gross_price),2) as total_gross_price
from fact_sales_monthly s
join fact_gross_price g
on s.product_code = g.product_code and 
g.fiscal_year = get_fiscal_year(s.date)
where customer_code = 90002002
group by s.date 
order by s.date;

-- Yearly report for Croma India where there are two columns
-- 1. Fiscal Year
-- 2. Total Gross Sales amount In that year from Croma
select 
	get_fiscal_year(s.date) as fiscal_year, 
	sum(round(s.sold_quantity*g.gross_price,2)) as yearly_price
from fact_sales_monthly s
join fact_gross_price g
on 
	s.product_code = g.product_code and 
	g.fiscal_year = get_fiscal_year(s.date)
where 
	customer_code = 90002002
group by fiscal_year
order by fiscal_year;

-- Generate report of net sales for given fiscal year for
-- 1. Top markets
-- 2. Top products
-- 3. Top customers

-- joining fact_pre_invoice_deductions table to get pre_invoice_discount_pct

explain analyze
select 
	f.date, 
    f.product_code, 
    p.product, p.variant, f.sold_quantity, g.gross_price,
	round(f.sold_quantity * g.gross_price,2) as gross_total_price, 
    pre.pre_invoice_discount_pct,
    f.customer_code,
    get_fiscal_year(f.date) as fiscal_year
from 
	fact_sales_monthly f
join 
	dim_product p
using 
	(product_code)
join fact_gross_price g
on	
	g.product_code = f.product_code and
	g.fiscal_year = get_fiscal_year(f.date)
join fact_pre_invoice_deductions as pre
on 
	pre.customer_code = f.customer_code
	and pre.fiscal_year =  get_fiscal_year(f.date)
where 
	 get_fiscal_year(f.date) = 2021
limit 10000000;

-- get_fiscal_year consuming more execution time
-- methods to improve:
-- 1. Lookup table to find fiscal_year for repeated dates

SELECT * FROM gdb041.dim_date;
-- input data for dim_date imported from csv

-- optimised query
explain analyze
select 
	f.date, f.product_code, 
    p.product, p.variant, f.sold_quantity, g.gross_price,
	round(f.sold_quantity * g.gross_price,2) as gross_total_price, 
    pre.pre_invoice_discount_pct, f.customer_code,
    dt.fiscal_year as fiscal_year
from 
	fact_sales_monthly f
join 
	dim_product p
using (product_code)
join dim_date dt
on dt.calender_date = f.date
join fact_gross_price g
on	g.product_code = f.product_code and
	g.fiscal_year = dt.fiscal_year
join fact_pre_invoice_deductions as pre
on pre.customer_code = f.customer_code
	and pre.fiscal_year =  dt.fiscal_year
where 
	 dt.fiscal_year = 2021
limit 10000000;


-- 2. Add column into fact_sales_monthly table. This method consumes more space compared to the dim_table approach
SELECT * FROM gdb041.fact_sales_monthly;

#explain analyze
with cte1 as(
select 
	f.date, f.fiscal_year, f.customer_code, c.market,
    f.product_code, p.product, p.variant, f.sold_quantity, g.gross_price,
	round(f.sold_quantity * g.gross_price,2) as gross_total_price, 
    pre.pre_invoice_discount_pct
from 
	fact_sales_monthly f
join 
	dim_product p
using (product_code)

join fact_gross_price g
on	g.product_code = f.product_code and
	g.fiscal_year = f.fiscal_year
join fact_pre_invoice_deductions as pre
on pre.customer_code = f.customer_code
	and pre.fiscal_year =  f.fiscal_year
join dim_customer c
on f.customer_code =  c.customer_code)
 
select *,
    gross_total_price - (gross_total_price * pre_invoice_discount_pct) as net_invoice_sales
from cte1;

-- inorder to simplify the query create sales_preinv_discount view 
select s.date, s.fiscal_year,
		s.customer_code, s.market,
        s.product, s.product_code, s.variant, 
        s.sold_quantity, s.gross_total_price, 
        s.pre_invoice_discount_pct,
	(1 - pre_invoice_discount_pct)*gross_total_price  as net_invoice_sales,
    (po.discounts_pct + po.other_deductions_pct) as post_invoice_discount_pct
from sales_preinv_discount s
join fact_post_invoice_deductions po 
on s.customer_code = po.customer_code and
	s.date = po.date and
    s.product_code = po.product_code;
    
-- create view sales_postinv_discount with above query to calculate net sales
-- create net sales view



