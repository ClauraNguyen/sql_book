----- CODE ORGANIZATION
/*

*/
SELECT type, mag
,case when place like '%CA%' then 'California'
      when place like '%AK%' then 'Alaska'
      else trim(split_part(place,',',2)) 
      end as place
,count(*)
FROM earthquakes
WHERE date_part('year',time) >= 2019
and mag between 0 and 1
GROUP BY 1,2,3
;

----- ORGANIZING COMPUTATIONS
-- SQL CLAUSE ORDER
/*
where -> group -> having
*/
SELECT state
,count(*) as terms
FROM legislators_terms
GROUP BY 1
HAVING count(*) >= 1000
ORDER BY 2 desc
;

/*
where -> group -> having -> window, can use agg
*/
SELECT state
,count(*) as terms
,avg(count(*)) over () as avg_terms
FROM legislators_terms
GROUP BY 1
;

/*
also by order by
*/
SELECT state
,count(*) as terms
,rank() over (order by count(*) desc)
FROM legislators_terms
GROUP BY 1
;

-- SUBQUERIES
/*
Lateral -> a little use
*/
SELECT date_part('year',c.first_term) as first_year
,a.party
,count(a.id_bioguide) as legislators
FROM
(
        SELECT distinct id_bioguide, party
        FROM legislators_terms
        WHERE term_end > '2020-06-01'
) a,
LATERAL
(
        SELECT b.id_bioguide
        ,min(term_start) as first_term
        FROM legislators_terms b
        WHERE b.id_bioguide = a.id_bioguide
        and b.party <> a.party
        GROUP BY 1
) c
GROUP BY 1,2
;

/*

*/
SELECT date_part('year',c.first_term) as first_year
,a.party
,count(a.id_bioguide) as legislators
FROM
(
        SELECT distinct id_bioguide, party
        FROM legislators_terms
        WHERE term_end > '2020-06-01'
) a
JOIN
(
        SELECT id_bioguide, party
        ,min(term_start) as first_term
        FROM legislators_terms
        GROUP BY 1,2
) c on c.id_bioguide = a.id_bioguide and c.party <> a.party
GROUP BY 1,2
;

-- TEMPORATY TABLES
/*

*/
CREATE temporary table temp_states
(
state varchar primary key
)
;


INSERT into temp_states
SELECT distinct state
FROM legislators_terms
;


CREATE temporary table temp_states
as
SELECT distinct state
FROM legislators_terms
;    

-- COMMON TABLE EXPRESSIONS
/*
CTE
*/
WITH first_term as
(
    SELECT id_bioguide
    ,min(term_start) as first_term
    FROM legislators_terms 
    GROUP BY 1
) 
SELECT date_part('year',age(b.term_start,a.first_term)) as periods
,count(distinct a.id_bioguide) as cohort_retained
FROM first_term a
JOIN legislators_terms b on a.id_bioguide = b.id_bioguide 
GROUP BY 1
;

-- GROUPING SETS
/*
Normal ways
*/
SELECT platform
,null as genre
,null as publisher
,sum(global_sales) as global_sales
FROM videogame_sales
GROUP BY 1,2,3
    UNION
SELECT null as platform
,genre
,null as publisher
,sum(global_sales) as global_sales
FROM videogame_sales
GROUP BY 1,2,3
    UNION
SELECT null as platform
,null as genre
,publisher
,sum(global_sales) as global_sales
FROM videogame_sales
GROUP BY 1,2,3
;

/*
Groupset ways
*/
SELECT platform, genre, publisher
,sum(global_sales) as global_sales
FROM videogame_sales
GROUP BY grouping sets (platform, genre, publisher)
;

/*
change Null -> All for cleaning
*/
SELECT coalesce(platform,'All') as platform
,coalesce(genre,'All') as genre
,coalesce(publisher,'All') as publisher
,sum(global_sales) as na_sales
FROM videogame_sales
GROUP BY grouping sets ((), platform, genre, publisher)
ORDER BY 1,2,3
;

/*
cube as same results
*/
SELECT coalesce(platform,'All') as platform
,coalesce(genre,'All') as genre
,coalesce(publisher,'All') as publisher
,sum(global_sales) as global_sales
FROM videogame_sales
GROUP BY cube (platform, genre, publisher)
ORDER BY 1,2,3
;

----- MANAGING DATA SET SIZE AND PRIVACY
-- colect a randomize sample from datasets
/*
by order
*/
SELECT 123456 % 100;

/*

*/
SELECT mod(123456,100);
-- REDUCING DIMENSIONALITY
/*
group groups
*/
SELECT case when state in ('CA','TX','FL','NY','PA') then state 
            else 'Other' end as state_group
,count(*) as terms
FROM legislators_terms
GROUP BY 1
ORDER BY 2 desc
;

/*
just 5 highest state + other
*/
SELECT case when b.rank <= 5 then a.state 
            else 'Other' end as state_group
,count(distinct id_bioguide) as legislators            
FROM legislators_terms a 
JOIN
(
        SELECT state
        ,count(distinct id_bioguide)
        ,rank() over (order by count(distinct id_bioguide) desc) 
        FROM legislators_terms
        GROUP BY 1
) b on a.state = b.state
GROUP BY 1
ORDER BY 2 desc
;

/*
catogarize continuous values - terms
*/
SELECT case when terms >= 2 then true else false end as two_terms_flag
,count(*) as legislators
FROM
(
    SELECT id_bioguide
    ,count(term_id) as terms
    FROM legislators_terms
    GROUP BY 1
) a
GROUP BY 1
;

/*
catogarize continuous values - terms
*/
SELECT 
case when terms >= 10 then '10+'
     when terms >= 2 then '2 - 9'
     else '1' end as terms_level
,count(*) as legislators
FROM
(
        SELECT id_bioguide
        ,count(term_id) as terms
        FROM legislators_terms
        GROUP BY 1
) a
GROUP BY 1
;
-- DATA PRIVACY
/*

*/
SELECT md5('my info');






