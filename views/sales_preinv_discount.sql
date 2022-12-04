CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `sales_preinv_discount` AS
    SELECT 
        `f`.`date` AS `date`,
        `f`.`fiscal_year` AS `fiscal_year`,
        `f`.`customer_code` AS `customer_code`,
        `c`.`market` AS `market`,
        `f`.`product_code` AS `product_code`,
        `p`.`product` AS `product`,
        `p`.`variant` AS `variant`,
        `f`.`sold_quantity` AS `sold_quantity`,
        `g`.`gross_price` AS `gross_price`,
        ROUND((`f`.`sold_quantity` * `g`.`gross_price`),
                2) AS `gross_total_price`,
        `pre`.`pre_invoice_discount_pct` AS `pre_invoice_discount_pct`
    FROM
        ((((`fact_sales_monthly` `f`
        JOIN `dim_product` `p` ON ((`f`.`product_code` = `p`.`product_code`)))
        JOIN `fact_gross_price` `g` ON (((`g`.`product_code` = `f`.`product_code`)
            AND (`g`.`fiscal_year` = `f`.`fiscal_year`))))
        JOIN `fact_pre_invoice_deductions` `pre` ON (((`pre`.`customer_code` = `f`.`customer_code`)
            AND (`pre`.`fiscal_year` = `f`.`fiscal_year`))))
        JOIN `dim_customer` `c` ON ((`f`.`customer_code` = `c`.`customer_code`)))