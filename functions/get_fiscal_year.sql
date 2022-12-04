CREATE DEFINER=`root`@`localhost` FUNCTION `get_fiscal_year`(
	calender_date date) RETURNS int
    DETERMINISTIC
-- Function returns fiscal year from calender date

BEGIN
	declare fiscal_year int;
    set fiscal_year = year(date_add(calender_date, interval 4 month));
    RETURN fiscal_year;
END