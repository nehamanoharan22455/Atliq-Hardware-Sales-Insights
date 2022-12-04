CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `sales_postinv_discount` AS
    SELECT 
        `s`.`date` AS `date`,
        `s`.`fiscal_year` AS `fiscal_year`,
        `s`.`customer_code` AS `customer_code`,
        `s`.`market` AS `market`,
        `s`.`product` AS `product`,
        `s`.`product_code` AS `product_code`,
        `s`.`variant` AS `variant`,
        `s`.`sold_quantity` AS `sold_quantity`,
        `s`.`gross_total_price` AS `gross_total_price`,
        `s`.`pre_invoice_discount_pct` AS `pre_invoice_discount_pct`,
        ((1 - `s`.`pre_invoice_discount_pct`) * `s`.`gross_total_price`) AS `net_invoice_sales`,
        (`po`.`discounts_pct` + `po`.`other_deductions_pct`) AS `post_invoice_discount_pct`
    FROM
        (`sales_preinv_discount` `s`
        JOIN `fact_post_invoice_deductions` `po` ON (((`s`.`customer_code` = `po`.`customer_code`)
            AND (`s`.`date` = `po`.`date`)
            AND (`s`.`product_code` = `po`.`product_code`))))