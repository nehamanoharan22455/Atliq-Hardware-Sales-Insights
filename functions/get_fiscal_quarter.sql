CREATE DEFINER=`root`@`localhost` FUNCTION `get_fiscal_quarter`(
	calender_date date) RETURNS char(2) CHARSET latin1
    DETERMINISTIC
-- function calculates fiscal quarter from calender date
BEGIN
	declare month tinyint;
    declare qtr char(2);
    set month = month(calender_date);
    case 
		when month in (9,10,11) then 
		set qtr = "q1";        
        when month in (12,1,2) then 
		 set qtr = "q2";         
        when month in (3,4,5) then 
		 set qtr = "q3";         
        else 
		 set qtr = "q4";        
    end case;
RETURN qtr;
END