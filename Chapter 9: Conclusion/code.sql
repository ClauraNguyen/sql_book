------------------------------------- funnel --------------------------------------------------------------------
-- note this is pseudocode
-- users for each step and percent pass to each step 
SELECT count(a.user_id) as all_users
,count(b.user_id) as step_one_users
,count(b.user_id) / count(a.user_id) as pct_step_one
,count(c.user_id) as step_two_users
,count(c.user_id) / count(b.user_id) as pct_one_to_two
FROM users a
LEFT JOIN step_one b on a.user_id = b.user_id
LEFT JOIN step_two c on b.user_id = c.user_id
;

SELECT count(a.user_id) as all_users
,count(b.user_id) as step_one_users
,count(b.user_id) / count(a.user_id) as pct_step_one
,count(c.user_id) as step_two_users
,count(c.user_id) / count(b.user_id) as pct_step_two
FROM users a
LEFT JOIN step_one b on a.user_id = b.user_id
LEFT JOIN step_two c on a.user_id = c.user_id
;

------------------------------------- churn, lapse --------------------------------------------------------------------
-- these examples use the legislators data set, which can be found in the Chapter 4 directory

-- average gaps find churn threshold (2 year, 2 mons)
SELECT avg(gap_interval) as avg_gap
FROM
(
        SELECT id_bioguide, term_start
        ,lag(term_start) over (partition by id_bioguide order by term_start) as prev
        ,age(term_start,lag(term_start) over (partition by id_bioguide order by term_start)) as gap_interval
        FROM legislators_terms
        WHERE term_type = 'rep'
) a
WHERE gap_months is not null
;

-- count by gap month btw each purchase / distribution of legth of gaps between representative term start dtes, showing range from 10 - 59 months. --> find churn threshold
SELECT gap_months, count(*)
FROM
(
        SELECT id_bioguide, term_start
        ,lag(term_start) over (partition by id_bioguide order by term_start) as prev
        ,age(term_start,lag(term_start) over (partition by id_bioguide order by term_start)) as gap_interval
        ,date_part('year',age(term_start,lag(term_start) over (partition by id_bioguide order by term_start))) * 12
          + date_part('month',age(term_start,lag(term_start) over (partition by id_bioguide order by term_start)))
          as gap_months
        FROM legislators_terms
        WHERE term_type = 'rep'
) a
WHERE gap_months is not null
GROUP BY 1
;


-- days since last
SELECT date_part('year',interval_since_last) as years_since_last
,count(*) as reps
FROM
(
        SELECT id_bioguide
        ,max(term_start) as max_date
        ,age('2020-05-19',max(term_start)) as interval_since_last
        FROM legislators_terms
        WHERE term_type = 'rep'
        GROUP BY 1
) a
GROUP BY 1
ORDER BY 1
;

-- count by churn status
SELECT 
case when months_since_last <= 23 then 'Current'
     when months_since_last <= 48 then 'Lapsed'
     else 'Churned' 
     end as status
,sum(reps) as total_reps     
FROM
(-- frequency of reps by period since last to 19/8/2020
        SELECT 
        date_part('year',interval_since_last) * 12 
         + date_part('month',interval_since_last)
         as months_since_last
        ,count(*) as reps
        FROM
        (-- period from last participate to 19/5/2020 as rep
                SELECT id_bioguide
                ,max(term_start) as max_date
                ,age('2020-05-19',max(term_start)) as interval_since_last
                FROM legislators_terms
                WHERE term_type = 'rep'
                GROUP BY 1
        ) a
        GROUP BY 1
) a
GROUP BY 1
;


------------------------------------- basket analysis --------------------------------------------------------------------
-- note this is pseudocode

-- number of customers purchased  backets of 2 products 
SELECT product1, product2
,count(customer_id) as customers
FROM
(-- list of customers purchase  baskets of 2 products
        SELECT a.customer_id
        ,a.product as product1
        ,b.product as product2
        FROM purchases a
        JOIN purchases b on a.customer_id = b.customer_id and b.product > a.product
) a
GROUP BY 1,2
ORDER BY 3 desc
;

-- number of customers purchased a list of products
SELECT products
,count(customer_id) as customers
FROM
(-- list of product purchase by each customer
        SELECT customer_id
        ,string_agg(product,', ') as products
        FROM purchases
        GROUP BY 1
) a
GROUP BY 1
ORDER BY 2 desc
;

