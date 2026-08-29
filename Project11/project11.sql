create warehouse scd_11_wh
with 
warehouse_size='xsmall'
auto_resume=True 
auto_suspend=60;



show resource monitors;

use warehouse scd_11_wh;

alter warehouse scd_11_wh
set resource_monitor=credits_usage;

create database scd_11_db;

use database scd_11_db;

create schema scd_11_schema;
use schema scd_11_schema;

-- input files 
create or replace table customers_initial(
customer_id int primary key ,
customer_name varchar(50),
city varchar(50),
state varchar(50),
membership varchar(50),
segment varchar(50)
);

create or replace table customer_updates(
customer_id int primary key, 
customer_name varchar(50),
city varchar(50),
state varchar(50),
membership varchar(50),
segment varchar(50),
effective_date date 

);

-- task 2 creating hybrid dimension table 
create or replace table dim_customer_hybrid(
customer_key int primary key autoincrement,
customer_id int,
customer_name varchar(50),
city varchar(50),
previous_city varchar(50),
state varchar(50),
current_membership varchar(50),
previous_membership varchar(50),
historical_membership varchar(50),
segment varchar(50),
effective_date date, 
expiry_date date, 
is_current boolean default true 
);

-- before task 3 we have create stage and load those data tables
create stage scd_11_stage;
create file format csv_format
type = 'csv'
field_delimiter=','
skip_header=1;

copy into customers_initial 
from @scd_11_stage/customers_initial.csv
file_format=(format_name=csv_format);

copy into customer_updates
from @scd_11_stage/customer_updates.csv
file_format=(format_name=csv_format);

-- task 3 
insert into dim_customer_hybrid(
customer_id ,
customer_name ,
city ,
previous_city ,
state ,
current_membership ,
previous_membership ,
historical_membership ,
segment ,
effective_date ,
expiry_date ,
is_current  )
select 
customer_id ,
customer_name ,
city ,
null as previous_city ,
state ,
membership as current_membership ,
null as previous_membership ,
membership as historical_membership ,
segment ,
'2026-01-01' as effective_date ,
'9999-12-31' as expiry_date ,
true as is_current 
from customers_initial;


select count(*) as Total_Records,
count_if(is_current=true) as "current records",
count_if(is_current=false) as "Historical records"
from dim_customer_hybrid;


-- task 4
-- display initial dimension state 
select * from dim_customer_hybrid;


-- task 5
-- step 1
-- expire active versions of updated customers
update dim_customer_hybrid dch
set 
is_current=False 
from customer_updates u 
where u.customer_id=dch.customer_id 
and dch.is_current=True;

update dim_customer_hybrid dch 
set 
expiry_date = u.effective_date-1
from customer_updates u 
where u.customer_id=dch.customer_id 
and dch.is_current=False 
and dch.effective_date < u.effective_date;

-- step2
select * from customer_updates;
-- insert new active versions


insert into dim_customer_hybrid(
customer_id,
customer_name,
city,
previous_city,
state,
current_membership,
previous_membership,
historical_membership,
segment,
effective_date,
expiry_date,
is_current
)
select 
u.customer_id,
u.customer_name,
u.city,
CASE
        WHEN d.city <> u.city THEN d.city
        ELSE NULL
    END AS previous_city,
u.state,
u.membership as current_membership,
d.current_membership as previous_membership,
u.membership as hisorical_membership,
u.segment,
u.effective_date,
'9999-12-31',
true 
from customer_updates u 
join dim_customer_hybrid d 
on u.customer_id=d.customer_id
where d.expiry_date=u.effective_date-1;


-- select * from dim_customer_hybrid;
-- step 3 



UPDATE dim_customer_hybrid d
SET
    d.previous_city = d.city,
    d.city = u.city,
    d.state = u.state,
    d.previous_membership = d.current_membership,
    d.current_membership = u.membership
FROM customer_updates u
WHERE d.customer_id = u.customer_id
  AND d.expiry_date = u.effective_date - 1;



-- TASK 6 — Display Complete Dimension History
  select * from dim_customer_hybrid order by customer_id;

-- TASK 7 — Display Active Customer Report
select * exclude (customer_key,EFFECTIVE_DATE,EXPIRY_DATE,IS_CURRENT,HISTORICAL_MEMBERSHIP) from dim_customer_hybrid
where is_current=true order by customer_id;


-- task 8 point in time 
SELECT
    customer_id,
    customer_name,
    city,
    historical_membership,
    segment,
    effective_date,
    expiry_date
FROM dim_customer_hybrid
WHERE customer_id = 101
  AND '2026-03-15' BETWEEN effective_date AND expiry_date;


  -- task 9
  SELECT
    COUNT(*) AS "TOTAL RECORD COUNT",
    COUNT_IF(is_current = TRUE) AS "CURRENT RECORD COUNT",
    COUNT_IF(is_current = FALSE) AS "HISTORICAL RECORD COUNT"
FROM dim_customer_hybrid;
