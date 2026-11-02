Create database zomato_analytics;
use zomato_analytics;

CREATE TABLE zomato(
    RestaurantID VARCHAR(50),
    RestaurantName TEXT,
    CountryName VARCHAR(100),
    CountryCode VARCHAR(50),
    City VARCHAR(100),
    Address TEXT,
    Locality TEXT,
    LocalityVerbose TEXT,
    Longitude VARCHAR(50),
    Latitude VARCHAR(50),
    Cuisines TEXT,
    Currency VARCHAR(100),
    Has_Table_booking VARCHAR(20),
    Has_Online_delivery VARCHAR(20),
    Is_delivering_now VARCHAR(20),
    Switch_to_order_menu VARCHAR(20),
    Price_range VARCHAR(50),
    Votes VARCHAR(50),
    Average_Cost_for_two VARCHAR(50),
    Rating VARCHAR(50),
    Datekey_Opening VARCHAR(50),
    Opening_Date VARCHAR(50)
);

SET NAMES 'utf8';

LOAD DATA LOCAL INFILE 'C:/Users/kastu/Downloads/zomato.csv'
INTO TABLE zomato
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

show variables like "secure_file_priv";

show variables like "local_infile";

set global local_infile = 1;

ALTER DATABASE zomato_analytics CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

ALTER TABLE  zomato convert to CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE zomato MODIFY CountryName VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

select* from zomato;

SHOW VARIABLES LIKE 'character_set_server';

SHOW VARIABLES LIKE 'character_set_client';
-------------------------------------------------------------------------------------------------------------------------------------------

select * from zomato;

# KPIs

# Total Restaurant
select Count(RestaurantName) as Total_Restaurant from zomato;
SELECT COUNT(DISTINCT RestaurantID) AS Total_Restaurants FROM Zomato;

# Total Countries
SELECT COUNT(DISTINCT CountryCode) AS Total_Countries FROM Zomato;
SELECT COUNT(DISTINCT CountryName) AS Total_Countries FROM Zomato;

#Total Cities
SELECT COUNT(DISTINCT City) AS Total_Cities FROM Zomato;

# Total Votes
SELECT SUM(Votes) AS Total_Votes FROM Zomato;

# Average Rating
SELECT ROUND(AVG(Rating),2) AS Average_Rating FROM Zomato WHERE Rating > 0;

# Average Cost for two
SELECT CONCAT('₹ ', ROUND(AVG(Average_Cost_for_two), 2)) AS Avg_Cost_For_Two FROM Zomato;

-------------------------------------------------------------------------------------------------------------------------------------------
# Visulation

# 1. Build a country Map Table
create table countries as select distinct CountryCode, CountryName from zomato;
Select * from countries;
-------------------------------------------------------------------------------------------------------------------------------------------
/* #2. Build a Calendar Table using the Column Datekey
  Add all the below Columns in the Calendar Table using the Formulas.
   A.Year
   B.Monthno
   C.Monthfullname
   D.Quarter(Q1,Q2,Q3,Q4)
   E. YearMonth ( YYYY-MMM)
   F. Weekdayno
   G.Weekdayname
   H.FinancialMOnth ( April = FM1, May= FM2  …. March = FM12)
   I. Financial Quarter ( Quarters based on Financial Month)*/

create table Calender as select Datekey_Opening from zomato;
Select * from Calender;

alter table Calender
add column OrderDateActual DATE,
add column Year INT,
add column MonthNo INT,
add column MonthFullName VARCHAR(20),
add column Quarter VARCHAR(10),
add column YearMonth VARCHAR(20),
add column WeekdayNo INT,
add column WeekdayName VARCHAR(20),
add column FinancialMonth INT,
add column FinancialQuarter VARCHAR(10);

select * from calender;

SET SQL_SAFE_UPDATES = 0;

-- Create actual date from OrderDateKey
update calender set OrderDateActual = STR_TO_DATE(datekey_Opening, '%Y_%m_%d');

-- Year, Month Number and Month Name    
update calender set Year = year(orderdateactual), MonthNo = month(orderdateactual), MonthFullName = monthname(orderdateactual);   

-- Quarter and YearMonth
update calender set Quarter = concat('Q', quarter(orderdateactual)), YearMonth = Date_Format(orderdateactual, '%Y-%b');

-- Weekday Number and Weekday Name
update calender set  WeekdayNo = dayofweek(orderdateactual), weekdayname = dayname(orderdateactual);

-- Financial Month (Financial Year starts from april)
update calender set FinancialMonth = case when monthno >= 4 then monthno - 4 else monthno +9 end;

-- Financial Quater
update Calender set FinancialQuarter =
CASE 
WHEN MonthNo BETWEEN 4 AND 6 THEN 'Q1'
WHEN MonthNo BETWEEN 7 AND 9 THEN 'Q2' 
WHEN MonthNo BETWEEN 10 AND 12 THEN 'Q3'
WHEN MonthNo BETWEEN 1 AND 3 THEN 'Q4' 
END;

SELECT DateKey_Opening,OrderDateActual,
Year,MonthNo,MonthFullName,
Quarter,YearMonth,
WeekdayNo,WeekdayName,
FinancialMonth,FinancialQuarter
FROM calender;
-------------------------------------------------------------------------------------------------------------------------------------------
#3. Number of restaurants based on City and Country

select City,CountryName, count(RestaurantID) as Total_Restaurant from zomato 
group by city, CountryName
order by Total_Restaurant Desc;
-------------------------------------------------------------------------------------------------------------------------------------------
#4. Number of restaurants opening based on Year, Quarter, and Month
Alter table Zomato
add column OrderDateActual DATE,
add column Year INT,
add column MonthNo INT,
add column Quarter VARCHAR(10);

select * from zomato;

SET SQL_SAFE_UPDATES = 0;

-- Create actual date from OrderDateKey
update zomato set OrderDateActual = STR_TO_DATE(datekey_Opening, '%Y_%m_%d');

-- Year and Month Number 
update zomato set Year = year(orderdateactual), MonthNo = month(orderdateactual);  

-- Quarter 
update Zomato set Quarter = concat('Q', quarter(orderdateactual));

select	year, MonthNo, Quarter, count(RestaurantID) as Total_Restuarants from zomato 
group by year, monthno, quarter order by total_restuarants;
-------------------------------------------------------------------------------------------------------------------------------------------
#5. Count of restaurants based on Average Ratings

select Rating AS Agg_Rating,
    COUNT(RestaurantID) AS Total_Restaurants
FROM zomato
GROUP BY Agg_Rating
ORDER BY Agg_Rating DESC;
-------------------------------------------------------------------------------------------------------------------------------------------
#6.Create buckets based on Average Price of reasonable size and find out how many resturants falls in each buckets

SELECT
    CASE
        WHEN Average_Cost_for_two <= 500 THEN '0-500'
        WHEN Average_Cost_for_two <= 1000 THEN '501-1000'
        WHEN Average_Cost_for_two <= 2000 THEN '1001-2000'
        WHEN Average_Cost_for_two <= 5000 THEN '2001-5000'
        ELSE 'Above 5000'
    END AS Price_Bucket,
    COUNT(RestaurantID) AS Total_Restaurants
FROM zomato
WHERE Average_Cost_for_two IS NOT NULL
GROUP BY Price_Bucket
ORDER BY MIN(Average_Cost_for_two);
-------------------------------------------------------------------------------------------------------------------------------------------
#7. Percentage of restaurants based on Has_Table_booking
SELECT
    Has_Table_booking AS Table_Booking,
    COUNT(RestaurantID) AS Total_Restaurants,
    ROUND(
        COUNT(RestaurantID) * 100.0 /
        (SELECT COUNT(*) FROM zomato),2) AS Percentage
FROM zomato
GROUP BY Has_Table_booking;
-------------------------------------------------------------------------------------------------------------------------------------------
#8.Percentage of Resturants based on "Has_Online_delivery"
SELECT
Has_Online_delivery AS Online_delivery,
    COUNT(RestaurantID) AS Total_Restaurants,
    ROUND(COUNT(RestaurantID) * 100.0 /
        (SELECT COUNT(*) FROM zomato),2) AS Percentage
FROM zomato
GROUP BY Has_Online_delivery;
-------------------------------------------------------------------------------------------------------------------------------------------
#9. Resturant By Price 
Select Price_range , RestaurantName, count(RestaurantID) from zomato
group by Price_range, RestaurantName 
order by Price_range desc;
-------------------------------------------------------------------------------------------------------------------------------------------
# 10. Restaurants Opened per Year
select year, count(RestaurantID)as Total_Restuarants from zomato
group by year
order by year;
-------------------------------------------------------------------------------------------------------------------------------------------
#11. Top 5 cities by Number of Restaurants
select City, count(RestaurantID) as Total_Cities from zomato
Group by City
order by Total_Cities Desc limit 5;
------------------------------------------------------------------------------------------------------------------------------------------
#12. Top 10 Cuisines by Number of Restaurants
select Cuisines, count(RestaurantID) as Total_Restuarants from zomato
Group by Cuisines 
order by Total_Restuarants Desc limit 10;
------------------------------------------------------------------------------------------------------------------------------------------
#13. Top 3 restaurants by rating
select RestaurantID, RestaurantName, city, rating from zomato order by rating desc limit 3;



