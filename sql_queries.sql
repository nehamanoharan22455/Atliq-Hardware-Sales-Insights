-- Title: Genereate sales insight for Atliq Hardware
-- Tool used: Mysql

-- 1. Generate report of individual product sales(aggregated on monthly basis on product_code level) for Croma India customer for FY = 2021. Fiscal year starts from Sept
-- Retrieving customer_code for Croma India
		SELECT customer_code FROM gdb041.dim_customer
		where customer like '%croma%' and market = "india";
 
-- Fiscal year is calculated using user defined function get_fiscal_year
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

-- 2. Generate report for 4th quarter
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

-- 3. Aggregate monthly report for Croma India fields to be included in the report
-- i) Month
-- ii) Gross sales for that month
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
-- The above query is converted into stored procedure 'get_monthly_gross_sales' 
 
-- 4. Yearly report for Croma India including:
-- i) Fiscal Year
-- ii) Total Gross Sales amount in that year from Croma
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


-- 5. Stored procedure to determine the market badge 
-- Procedure name: get_market_badge
-- Logic: If total sold quantity > 5 million then Gold badge else Silver
-- Input: fiscal year, market

-- 6. Generate report of net sales for given fiscal year for
-- i) Top markets
-- ii) Top products
-- iii) Top customers

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

-- get_fiscal_year() consuming more execution time, above query takes 27.23s for execution
-- Methods to improve query performance:
-- 1. Lookup table to find fiscal_year for repeated dates

-- input data for dim_date imported from csv
SELECT * FROM gdb041.dim_date;

-- Optimised query - execution time 0.078s
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

-- Optimised query - execution time 0.000s
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

-- Inorder to simplify the query create sales_preinv_discount view 
-- Create view sales_postinv_discount with above query to calculate net sales
-- Create view for net sales 

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
    
-- 7. Bar chart report of FY = 2021 for top 10 customers by % net sales
-- Query output exported to generate graph
		with cte1 as(
		SELECT 
					customer, 
					round(sum(net_sales)/1000000,2) as net_sales_million 
				FROM gdb041.net_sales ns
				join dim_customer c
				on c.customer_code = ns.customer_code
				where fiscal_year = 2021 
				group by customer)
		select 
			*,
			net_sales_million*100/sum(net_sales_million) over() as pct__net_sales
		from cte1 
		order by net_sales_million desc
		limit 10;

-- 8. Region wise net sales breakdown
-- Query output could be exported to generate graph 
		with cte as (
		SELECT 
			customer,
			market,
			region,
			round(sum(net_sales)/1000000, 2) as net_sales_million
		FROM gdb041.net_sales
		join dim_customer
		using (customer_code, market)
		where fiscal_year = 2021
		group by customer, region)

		select 
			*,
			(net_sales_million*100)/sum(net_sales_million) over(partition by region ) as percentage_contribution
		from cte
		order by region, net_sales_million desc;


-- 9. Top n products in each division by quantity sold in given FY
-- Stored procedure: top_n_products_per_division_by_qty_sold
-- Input: fiscal year, number of products


-- 10. Generate forecast accuracy report for all customers for a given fiscal year
-- Fields to be included in the report: Cusotmer code, Customer name, Market, Total sold quantity, Total forecast quantity, Net error, Absolute error, Forecast accuracy percentage

-- Business approved equations:
-- forecast_quantity - sold_quantity = net error
-- (forecast_quantity - sold_quantity)*100/forecast_quantity = net error percentage
-- abs(forecast_quantity - sold_quantity) = absolute error,
-- abs(forecast_quantity - sold_quantity)*100/forecast_quantity = absolute error percentage
-- (100 - absolute error percentage) = forecast accuracy 

-- Create helper table (fact_actual_estimate) with actual sold quantity and forecasted quantity to simplify the sql query during report generation
		create table fact_actual_estimate
		(
			select 
				s.date as date,
				s.fiscal_year as fiscal_year,
				s.product_code as product_code,
				s.customer_code as customer_code,
				s.sold_quantity as sold_quantity,
				f.forecast_quantity as forecast_quantity
			from fact_sales_monthly s 
			left join fact_forecast_monthly f
			using (date, product_code, customer_code)
			
			union
			
			select 
				f.date as date,
				f.fiscal_year as fiscal_year,
				f.product_code as product_code,
				f.customer_code as customer_code,
				s.sold_quantity as sold_quantity,
				f.forecast_quantity as forecast_quantity
			from fact_forecast_monthly f
			left join fact_sales_monthly s 
			using (date, product_code, customer_code)
		);


-- Update fact_actual_estimate to replace null values in sold_quantity and forecast_quantity as 0
		set sql_safe_update = 0;
		update fact_actual_estimate
		set forecast_quantity = 0
		where forecast_quantity is null or sold_quantity is null;
		set sql_safe_update = 0;

-- Set trigger to update fact_actual_estimate table whenever new record is added to fact_forecast_monthly and fact_sales_monthly 
-- On duplicate key records will be updated on insertion 


-- Stored procedure forecast_accuracy_report makes use of fact_actual_estimate and dim_customer table to generate the report
-- Input: fiscal year
-- Output: Report including: Cusotmer code, Customer name, Market, Total sold quantity, Total forecast quantity, Net error, Absolute error, Forecast accuracy percentage

-- Query optimization
-- Duration of the query is 0.922s
		explain analyze
		select * from fact_actual_estimate where fiscal_year = 2021 limit 1000000;


-- After adding indexing to fiscal_year duration 0.047s
		explain analyze
		select * from fact_actual_estimate where fiscal_year = 2021 limit 1000000;














