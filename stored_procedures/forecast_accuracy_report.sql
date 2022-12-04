CREATE DEFINER=`root`@`localhost` PROCEDURE `forecast_accuracy_report`(
	in in_fiscal_year int)
BEGIN
		with forecast_error as (SELECT 
			*,
            sum(sold_quantity) as total_sold_quantity,
            sum(forecast_quantity) as total_forecast_quantity,
			sum(forecast_quantity - sold_quantity) as net_error,
			sum((forecast_quantity - sold_quantity))*100/sum(forecast_quantity) as net_error_pct,
			sum(abs(forecast_quantity - sold_quantity)) as absolute_error,
			sum(abs(forecast_quantity - sold_quantity))*100/sum(forecast_quantity) as abs_error_pct
		FROM gdb041.fact_actual_estimate 
		where fiscal_year = in_fiscal_year
		group by customer_code)
		select 
			f.customer_code, c.customer as customer_name, c.market,
            f.total_sold_quantity, f.total_forecast_quantity, 			
			f.net_error, f.net_error_pct, f.absolute_error, f.abs_error_pct,
			if(abs_error_pct > 100, 0 ,(100 - abs_error_pct)) as forecast_accuracy 
		from forecast_error f
		join dim_customer c
		using (customer_code)
		order by forecast_accuracy desc;
END