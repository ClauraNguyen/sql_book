-- TRENDING THE DATA
-- SIMPLE TRENDS 

SELECT sales_month
,sales
FROM retail_sales
WHERE kind_of_business = 'Retail and food services sales, total'
ORDER BY 1
;

/* 
Total Retail and Food Service Sales By Years
*/
SELECT date_part('year',sales_month) as sales_year
,sum(sales) as sales
FROM retail_sales
WHERE kind_of_business = 'Retail and food services sales, total'
GROUP BY 1
ORDER BY 1
;

--  COMPARING COMPONENTS

/*
Yearly Sporting Goods, Hobby, Musical Instructment, and Book Store Sales
*/
SELECT date_part('year',sales_month) as sales_year
,kind_of_business
,sum(sales) as sales
FROM retail_sales
WHERE kind_of_business in ('Book stores','Sporting goods stores','Hobby, toy, and game stores')
GROUP BY 1,2
ORDER BY 1,2
;

/*
Monthly Women's and Men's Clothing Stores Sales
*/
SELECT sales_month
,kind_of_business
,sales
FROM retail_sales
WHERE kind_of_business in ('Men''s clothing stores','Women''s clothing stores')
ORDER BY 1,2
;

/*
Yearly Women's and Men's Clothing Stores Sales
*/
SELECT date_part('year',sales_month) as sales_year
,kind_of_business
,sum(sales) as sales
FROM retail_sales
WHERE kind_of_business in ('Men''s clothing stores','Women''s clothing stores')
GROUP BY 1,2
;

/*
PIVOT - Yearly Women's and Men's Clothing Stores Sales
*/
SELECT date_part('year',sales_month) as sales_year
,sum(case when kind_of_business = 'Women''s clothing stores' then sales end) as womens_sales
,sum(case when kind_of_business = 'Men''s clothing stores' then sales end) as mens_sales
FROM retail_sales
WHERE kind_of_business in ('Men''s clothing stores','Women''s clothing stores')
GROUP BY 1
ORDER BY 1
;

/*
PIVOT - Yearly Difference of Women's and Men's Clothing Stores Sales
*/
SELECT sales_year
,womens_sales - mens_sales as womens_minus_mens
,mens_sales - womens_sales as mens_minus_womens
FROM
(
        SELECT date_part('year',sales_month) as sales_year
        ,sum(case when kind_of_business = 'Women''s clothing stores' then sales end) as womens_sales
        ,sum(case when kind_of_business = 'Men''s clothing stores' then sales end) as mens_sales
        FROM retail_sales
        WHERE kind_of_business in ('Men''s clothing stores','Women''s clothing stores')
        and sales_month <= '2019-12-01'
        GROUP BY 1
) a
ORDER BY 1
;

/*
Yearly Difference between Women's and Men's Clothing Stores Sales
*/
SELECT date_part('year',sales_month) as sales_year
,sum(case when kind_of_business = 'Women''s clothing stores' then sales end) 
 - sum(case when kind_of_business = 'Men''s clothing stores' then sales end) as womens_minus_mens
FROM retail_sales
WHERE kind_of_business in ('Men''s clothing stores'
 ,'Women''s clothing stores')
and sales_month <= '2019-12-01'
GROUP BY 1
ORDER BY 1
;

/*
Yearly Ratio of Women's and Men's Clothing Stores Sales
*/
SELECT sales_year
,womens_sales / mens_sales as womens_times_of_mens
FROM
(
        SELECT date_part('year',sales_month) as sales_year
        ,sum(case when kind_of_business = 'Women''s clothing stores' then sales end) as womens_sales
        ,sum(case when kind_of_business = 'Men''s clothing stores' then sales end) as mens_sales
        FROM retail_sales
        WHERE kind_of_business in ('Men''s clothing stores','Women''s clothing stores')
        and sales_month <= '2019-12-01'
        GROUP BY 1
) a
ORDER BY 1
;

/*
Yearly Percent Difference between Women's and Men's Clothing Stores Sales
*/
SELECT sales_year
,(womens_sales / mens_sales - 1) * 100 as womens_pct_of_mens
FROM
(
        SELECT date_part('year',sales_month) as sales_year
        ,sum(case when kind_of_business = 'Women''s clothing stores' 
                  then sales 
                  end) as womens_sales
        ,sum(case when kind_of_business = 'Men''s clothing stores' 
                  then sales 
                  end) as mens_sales
        FROM retail_sales
        WHERE kind_of_business in ('Men''s clothing stores','Women''s clothing stores')
        and sales_month <= '2019-12-01'
        GROUP BY 1
) a
ORDER BY 1
;

-- PERCENT OF TOTAL CALCULATIONS
/*
Men's and Women's clothing stores sales as percent of monthly total
-- using aggregating and self-Join
*/

SELECT sales_month
,kind_of_business
,sales * 100 / total_sales as pct_total_sales
FROM
(
        SELECT a.sales_month
        ,a.kind_of_business
        ,a.sales
        ,sum(b.sales) as total_sales
        FROM retail_sales a
        JOIN retail_sales b on a.sales_month = b.sales_month
        and b.kind_of_business in ('Men''s clothing stores'
         ,'Women''s clothing stores')
        WHERE a.kind_of_business in ('Men''s clothing stores','Women''s clothing stores')
        GROUP BY 1,2,3
) aa
ORDER BY 1,2
;

-- Using sum window function
SELECT sales_month
,kind_of_business
,sales
,sum(sales) over (partition by sales_month) as total_sales
,sales * 100 / sum(sales) over (partition by sales_month) as pct_total
FROM retail_sales 
WHERE kind_of_business in ('Men''s clothing stores','Women''s clothing stores')
ORDER BY 1
;

/*
Percentage of yearly sales each month: Women's and Men's Clothing Stores
-- using self-join
*/
SELECT sales_month
,kind_of_business
,sales * 100 / yearly_sales as pct_yearly
FROM
(
        SELECT a.sales_month
        ,a.kind_of_business
        ,a.sales
        ,sum(b.sales) as yearly_sales
        FROM retail_sales a
        JOIN retail_sales b on date_part('year',a.sales_month) = date_part('year',b.sales_month)
        and a.kind_of_business = b.kind_of_business
        and b.kind_of_business in ('Men''s clothing stores','Women''s clothing stores')
        WHERE a.kind_of_business in ('Men''s clothing stores','Women''s clothing stores')
        GROUP BY 1,2,3
) aa
ORDER BY 1,2
;

/*
Percent of 2019 Yearly Sales by Month: Women's and Men's Clothing Stores
using window function
*/
SELECT sales_month, kind_of_business, sales
        ,sum(sales) over (partition by date_part('year',sales_month), kind_of_business) as yearly_sales
        ,sales * 100 / sum(sales) over (partition by date_part('year',sales_month), kind_of_business) as pct_yearly
FROM retail_sales 
WHERE kind_of_business in ('Men''s clothing stores','Women''s clothing stores')
ORDER BY 1,2
;


-- INDEXING TO SEE PERCENT CHANGE OVER TIME
/*
Sales and index_sales value
*/
SELECT sales_year, sales
,first_value(sales) over (order by sales_year) as index_sales
FROM
(
    SELECT date_part('year',sales_month) as sales_year
    ,sum(sales) as sales
    FROM retail_sales
    WHERE kind_of_business = 'Women''s clothing stores'
    GROUP BY 1
) a
;

/*
Percent change from 1992
*/
SELECT sales_year, sales
,(sales / index_sales - 1) * 100 as pct_from_index
FROM
(
        SELECT date_part('year',aa.sales_month) as sales_year
        ,bb.index_sales
        ,sum(aa.sales) as sales
        FROM retail_sales aa
        JOIN 
        (
                SELECT first_year, sum(a.sales) as index_sales
                FROM retail_sales a
                JOIN 
                (
                        SELECT min(date_part('year',sales_month)) as first_year
                        FROM retail_sales
                        WHERE kind_of_business = 'Women''s clothing stores'
                ) b on date_part('year',a.sales_month) = b.first_year 
                WHERE a.kind_of_business = 'Women''s clothing stores'
                GROUP BY 1
        ) bb on 1 = 1
        WHERE aa.kind_of_business = 'Women''s clothing stores'
        GROUP BY 1,2
) aaa
;

/*
Indexed Men's and Women's Clothing Stores Sales 
*/
SELECT sales_year, kind_of_business, sales
,(sales / first_value(sales) over (partition by kind_of_business order by sales_year) - 1) * 100 as pct_from_index
FROM
(
        SELECT date_part('year',sales_month) as sales_year
        ,kind_of_business
        ,sum(sales) as sales
        FROM retail_sales
        WHERE kind_of_business in ('Men''s clothing stores','Women''s clothing stores')  and sales_month <= '2019-12-31'
GROUP BY 1,2
) a
;

------- ROLLING TIME WINDOWS
-- CALCULATING ROLLING TIME WINDOWS
/*
Rolling Sales Month 
*/
SELECT a.sales_month
,a.sales
,b.sales_month as rolling_sales_month
,b.sales as rolling_sales
FROM retail_sales a
JOIN retail_sales b on a.kind_of_business = b.kind_of_business 
 and b.sales_month between a.sales_month - interval '11 months' 
 and a.sales_month
 and b.kind_of_business = 'Women''s clothing stores'
WHERE a.kind_of_business = 'Women''s clothing stores'
and a.sales_month = '2019-12-01'
;
/*
12 Month Moving Average sales for women's clothing stores 
*/
SELECT a.sales_month
,a.sales
,avg(b.sales) as moving_avg
,count(b.sales) as records_count
FROM retail_sales a
JOIN retail_sales b on a.kind_of_business = b.kind_of_business 
 and b.sales_month between a.sales_month - interval '11 months' 
 and a.sales_month
 and b.kind_of_business = 'Women''s clothing stores'
WHERE a.kind_of_business = 'Women''s clothing stores'
and a.sales_month >= '1993-01-01'
GROUP BY 1,2
ORDER BY 1
;

/*
Using windows function 
*/
SELECT sales_month
,avg(sales) over (order by sales_month rows between 11 preceding and current row) as moving_avg
,count(sales) over (order by sales_month rows between 11 preceding and current row) as records_count
FROM retail_sales
WHERE kind_of_business = 'Women''s clothing stores'
;

-- ROLLING TIME WINDOWS WITH SPARSE DATA
/*
12 sales monnth and sales with sparse data solution
*/
SELECT a.date, b.sales_month, b.sales
FROM date_dim a
JOIN 
(
        SELECT sales_month, sales
        FROM retail_sales 
        WHERE kind_of_business = 'Women''s clothing stores' 
        and date_part('month',sales_month) in (1,7) -- here we're artificially creating sparse data by limiting the months returned
) b on b.sales_month between a.date - interval '11 months' and a.date
WHERE a.date = a.first_day_of_month and a.date between '1993-01-01' and '2020-12-01'
ORDER BY 1,2
;

/*
12 Month Moving Average sales for women's clothing stores with sparse time solution
*/
SELECT a.date
,avg(b.sales) as moving_avg
,count(b.sales) as records
FROM date_dim a
JOIN 
(
        SELECT sales_month, sales
        FROM retail_sales 
        WHERE kind_of_business = 'Women''s clothing stores' and date_part('month',sales_month) in (1,7)
) b on b.sales_month between a.date - interval '11 months' and a.date
WHERE a.date = a.first_day_of_month and a.date between '1993-01-01' and '2020-12-01'
GROUP BY 1
ORDER BY 1
;

/*
12 Month Moving Average sales for women's clothing stores without sparse time solution
*/
SELECT a.sales_month
,avg(b.sales) as moving_avg
FROM
(
        SELECT distinct sales_month
        FROM retail_sales
        WHERE sales_month between '1993-01-01' and '2020-12-01'
) a
JOIN retail_sales b on b.sales_month between a.sales_month - interval '11 months' and a.sales_month
and b.kind_of_business = 'Women''s clothing stores' 
GROUP BY 1
;

-- CALCULATING CUMULATIVE VALUES

/*
Cumulative annual sales for women's clothing stores 
*/
SELECT sales_month
,sales
,sum(sales) over (partition by date_part('year',sales_month) order by sales_month) as sales_ytd
FROM retail_sales
WHERE kind_of_business = 'Women''s clothing stores'
;

/*
Cumulative annual sales for women's clothing stores 
using self-JOIN
*/
SELECT a.sales_month, a.sales
,sum(b.sales) as sales_ytd
FROM retail_sales a
JOIN retail_sales b on date_part('year',a.sales_month) = date_part('year',b.sales_month)
 and b.sales_month <= a.sales_month
 and b.kind_of_business = 'Women''s clothing stores'
WHERE a.kind_of_business = 'Women''s clothing stores'
GROUP BY 1,2
;

------- ANALYZING WITH SEASONALITY
-- PERIOD OVER PERIOD COMPARISONS
/*
Find last month and last sales month
*/
SELECT kind_of_business, sales_month, sales
,lag(sales_month) over (partition by kind_of_business order by sales_month) as prev_month
,lag(sales) over (partition by kind_of_business order by sales_month) as prev_month_sales
FROM retail_sales
WHERE kind_of_business = 'Book stores'
;

/*
Percent growth from previous month for US retail book store sales 
*/
SELECT kind_of_business, sales_month, sales
,(sales / lag(sales) over (partition by kind_of_business order by sales_month) - 1) * 100 as pct_growth_from_previous
FROM retail_sales
WHERE kind_of_business = 'Book stores'
;

/*
Percent growth from previous year for US retail book store sales 
*/
SELECT sales_year, yearly_sales
,lag(yearly_sales) over (order by sales_year) as prev_year_sales
,(yearly_sales / lag(yearly_sales) over (order by sales_year) -1) * 100 as pct_growth_from_previous
FROM
(
        SELECT date_part('year',sales_month) as sales_year
        ,sum(sales) as yearly_sales
        FROM retail_sales
        WHERE kind_of_business = 'Book stores'
        GROUP BY 1
) a
;

-- PERIOD OVER PERIOD COMPARISONS - SAME MONTH VS. LAST YEAR
/*
Take the month part
*/
SELECT sales_month
,date_part('month',sales_month)
FROM retail_sales
WHERE kind_of_business = 'Book stores'
;

/*
previous year month and previous year sales
*/
SELECT sales_month
,sales
,lag(sales_month) over (partition by date_part('month',sales_month) order by sales_month) as prev_year_month
,lag(sales) over (partition by date_part('month',sales_month) order by sales_month) as prev_year_sales
FROM retail_sales
WHERE kind_of_business = 'Book stores'
;

/*
YoY absolute difference in sales, and YoY percent growth 
*/
SELECT sales_month, sales
,sales - lag(sales) over (partition by date_part('month',sales_month) order by sales_month) as absolute_diff
,(sales / lag(sales) over (partition by date_part('month',sales_month) order by sales_month) - 1) * 100 as pct_diff
FROM retail_sales
WHERE kind_of_business = 'Book stores'
;

/*
PIVOT - Monthly book store sales, 1992-1994
*/
SELECT date_part('month',sales_month) as month_number
,to_char(sales_month,'Month') as month_name
,max(case when date_part('year',sales_month) = 1992 then sales end) as sales_1992
,max(case when date_part('year',sales_month) = 1993 then sales end) as sales_1993
,max(case when date_part('year',sales_month) = 1994 then sales end) as sales_1994
FROM retail_sales
WHERE kind_of_business = 'Book stores' and sales_month between '1992-01-01' and '1994-12-01'
GROUP BY 1,2
;

-- Comparing to multiple prior periods
/*
same month sales over 3 prior year
*/
SELECT sales_month, sales
,lag(sales,1) over (partition by date_part('month',sales_month) order by sales_month) as prev_sales_1
,lag(sales,2) over (partition by date_part('month',sales_month) order by sales_month) as prev_sales_2
,lag(sales,3) over (partition by date_part('month',sales_month) order by sales_month) as prev_sales_3
FROM retail_sales
WHERE kind_of_business = 'Book stores'
;

/*
YoY percent growth from the prior three-year rolling average in mid 1990s
*/
SELECT sales_month, sales
,sales / avg(sales) over (partition by date_part('month',sales_month) order by sales_month rows between 3 preceding and 1 preceding) as pct_of_prev_3
FROM retail_sales
WHERE kind_of_business = 'Book stores'
;









