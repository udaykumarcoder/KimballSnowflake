PROJECT-3:Enterprise Incremental Sales Data Warehouse using Snowflake
----------
Problem Statement:
-------------------
A multinational retail company has already migrated its operational databases to the Snowflake Cloud Data Warehouse. Initially, the company performed a complete data migration and generated analytical reports for business users.

As the business expanded, new sales transactions started arriving every hour from multiple regional branches. Reloading the complete historical data every time became inefficient and increased processing time.

The data engineering team has been assigned to develop an Incremental Data Warehouse Pipeline capable of loading only newly arrived records while preserving historical data.

To improve warehouse reliability, the company also wants to maintain an audit trail, recover accidentally deleted data, create testing environments without duplicating storage, and automate daily data loading.

Your task is to implement the required Snowflake objects and generate analytical reports using the newly loaded data.

Project Objectives
--------------------
After completing this project, students will be able to 
Perform Incremental Data Loading
Use Snowflake Streams
Automate loading using Tasks
Recover historical data using Time Travel
Create Zero Copy Clones
Validate newly arrived records
Maintain Audit Logs
Generate analytical reports.

Input Files
------------
customers.csv
---------------
customer_id,customer_name,city,membership
1,Amit,Hyderabad,Gold
2,Priya,Bangalore,Silver
3,Rahul,Chennai,Gold
4,Neha,Pune,Silver
5,Arjun,Delhi,Platinum


products.csv
-------------
product_id,product_name,category,price
101,Laptop,Electronics,60000
102,Mobile,Electronics,25000
103,Keyboard,Accessories,1500
104,Mouse,Accessories,800
105,Monitor,Electronics,12000

branches.csv
------------
branch_id,branch_name,state
1,Hyderabad Branch,Telangana
2,Bangalore Branch,Karnataka
3,Delhi Branch,Delhi

sales_history.csv
------------------
sale_id,customer_id,product_id,branch_id,quantity,sale_date,total_amount
1,1,101,1,1,2026-07-01,60000
2,2,102,2,2,2026-07-02,50000
3,3,103,2,2,2026-07-03,3000
4,4,104,1,5,2026-07-04,4000
5,5,105,3,2,2026-07-05,24000


new_sales.csv
---------------
sale_id,customer_id,product_id,branch_id,quantity,sale_date,total_amount
6,1,102,1,1,2026-07-06,25000
7,2,105,2,1,2026-07-07,12000
8,3,101,3,1,2026-07-08,60000
9,4,103,1,2,2026-07-09,3000
10,5,102,3,1,2026-07-10,25000

your Tasks:
--------------
Phase-1 : Snowflake Environment
-------------------------------
1.Create Warehouse ENTERPRISE_WH
2.Create Database ENTERPRISE_DB
3.Create Schema SALES_SCHEMA
4.Create CSV File Format
5.Create Internal Stage

Phase-2 : Data Loading
-------------------------
6.Upload all CSV files.
7.Create all required tables.
8.Load sales_history.csv into SALES table.
9.Verify the loaded records.

Phase-3 : Incremental Loading
--------------------------------
10.Create a Stream on the SALES table.
11.Load new_sales.csv.
12.Display only newly inserted records using the Stream.
13.Merge newly arrived records into the SALES table.


Phase-4 : Data Validation
-------------------------
14.Identify duplicate Sale IDs.
15.Identify missing Customer IDs.
16.Display invalid Product IDs.
17.Count total newly inserted records.

Phase-5 : Time Travel
---------------------
18.Delete one sales record.
19.Recover the deleted record using Time Travel.
20.Verify recovery.


Phase-6 : Zero Copy Clone
-------------------------
21.Create a clone named: SALES_TEST
22.Display cloned records.
23.Insert one new record into the clone.
24.Verify that the original SALES table remains unchanged.

Phase-7 : Task Automation
-------------------------
25.Create a Task that automatically performs incremental loading every day.
26.Resume the Task.
27.Verify Task execution.


Phase-8 : Business Analytics
-----------------------------
Generate
28.Customer Revenue Report
29.Branch Revenue Report
30.Product Revenue Report
31.Monthly Revenue Report
32.Highest Revenue Customer
33.Highest Revenue Branch
34.Top Five Products
35.Customer Purchase Frequency
36.Running Revenue
37.Customer Ranking

Phase-9 : Views
----------------
38.Create View: CUSTOMER_REVENUE
39.Create Materialized View: BRANCH_REVENUE
40.Display data from both Views.


Expected Outputs
--------------------

Output-1:Customers Loaded Successfully

Output-2:Products Loaded Successfully

Output-3:Historical Sales Loaded

Output-4:New Sales Captured by Stream

Output-5:Incremental Load Completed

Output-6:Duplicate Record Report

Output-7:Missing Customer Report

Output-8:Recovered Records using Time Travel

Output-9:Clone Created Successfully

Output-10:Original Table Unchanged After Clone Modification

Output-11:Customer Revenue Report

Output-12:Branch Revenue Report

Output-13:Monthly Revenue Report

Output-14:Top Five Customers

Output-15:Top Five Products

Output-16:Customer Ranking

Output-17:Running Revenue

Output-18:Materialized View Output


Snowflake Concepts Covered:
----------------------------
Snowflake Administration:
-------------------------
Warehouse
Database
Schema
Stage
File Format

Data Engineering
----------------
COPY INTO
MERGE
Streams
Tasks
Time Travel
Zero Copy Clone

SQL Analytics:
-------------
JOIN
GROUP BY
HAVING
ORDER BY
CTE
Window Functions
Ranking

Snowflake Objects
-----------------
Views
Materialized Views

create resource monitor credits_limit_ext
with credit_quota = 10
triggers 
on 10 percent do notify 
on 15 percent do suspend_immediate;  
-- no need to create it separate once created it 
-- can be used in any project files 

create warehouse ENTERPRISE_WH
with 
warehouse_size='xsmall'
auto_suspend=60
auto_resume = true
initially_suspended=true;

use warehouse ENTERPRISE_WH;

alter warehouse ENTERPRISE_WH
set resource_monitor = credits_limit_ext;

show warehouses like 'ENTERPRISE_WH';

create database ENTERPRISE_DB;

use database ENTERPRISE_DB;

create schema SALES_SCHEMA;

use schema SALES_SCHEMA;

create file format csv_format
type = 'csv'
field_delimiter=','
skip_header=1;

create stage ENTERPRISE_STAGE
file_format = csv_format;

create table Customers(
customer_id int unique not null,
customer_name varchar(55),
city varchar(55),
membership varchar(55)
);

create table Products(
product_id int unique not null,
product_name  varchar(55),
category  varchar(55),
price decimal(10,2)
);

create table Branches (
branch_id int unique not null,
branch_name  varchar(55),
state varchar(55)
);

create table sales_history(
sale_id int ,
customer_id int,
product_id int,
branch_id int,
quantity int,
sale_date date,
total_amount decimal(10,2)
);


copy into Customers 
from @ENTERPRISE_STAGE/customers.csv;


copy into Products
from @ENTERPRISE_STAGE/products.csv;


copy into Branches
from @ENTERPRISE_STAGE/branches.csv;

copy into sales_history
from @ENTERPRISE_STAGE/sales_history.csv;

select * from sales_history;



create table sales_increment_history(
sale_id int ,
customer_id int,
product_id int,
branch_id int,
quantity int,
sale_date date,
total_amount decimal(10,2)
);

create stream sales_stream
on table sales_increment_history;


show streams;

-- list @ENTERPRISE_STAGE;

copy into sales_increment_history
from @ENTERPRISE_STAGE
files=('new_sales.csv')
file_format=(format_name='csv_format');

select * from sales_increment_history;

-- select sale_id,customer_id,product_id,branch_id,quantity,
-- sale_date,total_amount,metadata$action,metadata$isupdate
-- from sales_stream 
-- where metadata$action='insert';

select * from sales_stream;

select * from sales_history;

merge into sales_history as target
using sales_stream as source
on target.sale_id=source.sale_id
when not matched then 
insert(sale_id,
customer_id,
product_id,
branch_id ,
quantity,
sale_date,
total_amount)
values(
source.sale_id,
source.customer_id,
source.product_id,
source.branch_id ,
source.quantity,
source.sale_date,
source.total_amount
);

select * from sales_history;
select * from sales_stream;



-- identify duplicate sale_id

select sale_id,count(*) from sales_history
group by sale_id 
having count(*)>1;

-- identify missing customer_id

select sh.* from sales_history sh
left join Customers c 
on sh.customer_id=c.customer_id 
where c.customer_id is null;


-- display invalid product id

select sh.* from sales_history sh
left join Products p 
on sh.product_id=p.product_id
where p.product_id is null;


-- new inserted records count
select count(*) from sales_increment_history;

-- time travel to check retention period column 
show tables like 'sales_history';


select * from sales_history;

delete from sales_history
where sale_id = 3;

select * from sales_history
at (offset=>-60*5)
where sale_id=3;

-- insert back deleted data  

insert into sales_history
(
sale_id,
customer_id,
product_id,
branch_id ,
quantity,
sale_date,
total_amount
)
select 
sale_id,
customer_id,
product_id,
branch_id ,
quantity,
sale_date,
total_amount
from sales_history
at (offset=>-60*5)
where sale_id=3;

select count(*) from sales_history;


-- create clone names sales_test 

create table sales_test
clone sales_history;

-- display cloned records 

select * from sales_history;

-- insert one new record into the clone 
INSERT INTO SALES_TEST
VALUES (
    16,
    1,
    101,
    1,
    2,
    '2026-07-05',
    12000
);

select count(*) from sales_history;
select count(*) from sales_test;


select * from sales_test;


-- task automation that loads 
create task auto_increment_load
warehouse = ENTERPRISE_WH
schedule = 'USING CRON 0 1 * * * Asia/Kolkata'
as 
merge into sales_history as target 
using sales_stream as source 
on target.sale_id=source.sale_id
when not matched then
insert(
sale_id,
customer_id,
product_id,
branch_id ,
quantity,
sale_date,
total_amount
)
values(
source.sale_id,
source.customer_id,
source.product_id,
source.branch_id ,
source.quantity,
source.sale_date,
source.total_amount
);



alter task auto_increment_load
resume;

show tasks;

execute task auto_increment_load;

SELECT
    NAME,
    STATE,
    SCHEDULED_TIME,
    QUERY_START_TIME,
    COMPLETED_TIME,
    ERROR_MESSAGE
FROM TABLE(
    INFORMATION_SCHEMA.TASK_HISTORY(
        TASK_NAME => 'AUTO_INCREMENT_LOAD',
        RESULT_LIMIT => 10
    )
)
ORDER BY SCHEDULED_TIME DESC;


select count(*) from sales_increment_history;

INSERT INTO SALES_INCREMENT_HISTORY
VALUES (
    11,
    1,
    105,
    1,
    1,
    '2026-07-11',
    12000
);

select * from sales_stream;
select count(*) from sales_history;
execute task auto_increment_load;
select count(*) from sales_history;



-- phase business analytics 
-- customer revenue 
select c.customer_id,c.customer_name,
sum(sh.total_amount)
from sales_history sh join 
Customers c 
on c.customer_id=sh.customer_id
group by c.customer_id,c.customer_name;


-- branch revenue
SELECT
    b.BRANCH_ID,
    b.BRANCH_NAME,
    SUM(s.TOTAL_AMOUNT) AS REVENUE
FROM BRANCHES b
JOIN sales_history s
    ON b.BRANCH_ID = s.BRANCH_ID
GROUP BY
    b.BRANCH_ID,
    b.BRANCH_NAME
ORDER BY REVENUE DESC;

-- 30.Product Revenue Report
select p.product_id, p.product_name, sum(s.total_amount) as revenue
from products p 
join sales_history s on p.product_id=s.product_id
group by p.product_id, p.product_name
order by revenue desc;

-- monthly revenue

insert into sales_history(
sale_id,
customer_id,
product_id,
branch_id ,
quantity,
sale_date,
total_amount
)
values(100,
2,
101,
1 ,
1,
'2026-08-01',
500000);

-- monthly revenue
select date_trunc(month,sale_date) as month,sum(total_amount)
as total_revenue
from sales_history 
group by month;


-- 32.Highest Revenue Customer
WITH CUSTOMER_SALES AS (
    SELECT
        c.CUSTOMER_ID,
        c.CUSTOMER_NAME,
        SUM(s.TOTAL_AMOUNT) AS REVENUE
    FROM CUSTOMERS c
    JOIN sales_history s
        ON c.CUSTOMER_ID = s.CUSTOMER_ID
    GROUP BY
        c.CUSTOMER_ID,
        c.CUSTOMER_NAME
),
RANKED AS (
    SELECT
        *,
        RANK() OVER (ORDER BY REVENUE DESC) AS RNK
    FROM CUSTOMER_SALES
)
SELECT *
FROM RANKED
WHERE RNK = 1;



--  top 5 products

WITH PRODUCT_SALES AS (
    SELECT
        p.PRODUCT_ID,
        p.PRODUCT_NAME,
        p.CATEGORY,
        SUM(s.TOTAL_AMOUNT) AS REVENUE
    FROM PRODUCTS p
    JOIN sales_history s
        ON p.PRODUCT_ID = s.PRODUCT_ID
    GROUP BY
        p.PRODUCT_ID,
        p.PRODUCT_NAME,
        p.CATEGORY
)
SELECT
    *,
    ROW_NUMBER() OVER (ORDER BY REVENUE DESC) AS RNK
FROM PRODUCT_SALES
QUALIFY RNK <= 5
ORDER BY REVENUE DESC;



-- customer purschase frequency 
select c.customer_id,c.customer_name,count(sh.customer_id)
from Customers c join sales_history sh
on c.customer_id=sh.customer_id
group by c.customer_id,c.customer_name;


-- running revenue
select * from sales_history order by sale_id ;
select sale_id,sale_date,total_amount,sum(total_amount) over(order by sale_date,sale_id) as revenue 
from sales_history order by sale_id ;


-- customer ranking
with cte1 as (
select customer_id,sum(total_amount) as revenue
from sales_history
group by customer_id order by customer_id
)
select customer_id,revenue,rank() over(order by revenue desc) as rnk
from cte1;


-- create view customer_revenue

create view customer_rev as (
select customer_id,sum(total_amount) as revenue
from sales_history group by customer_id
);
select * from customer_rev;

-- materialized view customer

create materialized view branch_revenue as (
select branch_id,sum(total_amount) as revenue
from sales_history group by branch_id
);

select * from branch_revenue;

create warehouse enterprise_wh
warehouse_size='XSMALL'
auto_suspend=60
auto_resume=TRUE
initially_suspended=TRUE;

use warehouse enterprise_wh;

create database enterprise_db;

use enterprise_db;

create schema sales_schema;
use schema sales_schema;

create stage enterprise_stage;

create file format csv_format
type='csv'
field_delimiter=','
skip_header=1;

create table dim_customerS(
customer_id int primary key,
customer_name varchar(100),
city varchar(50),
membership varchar(50)
);
CREATE table dim_products(
product_id int primary key,
product_name varchar(100),
category varchar(50),
price number(10,2)
);
create table dim_branches(
branch_id int primary key,
branch_name varchar(100),
state varchar(100)

);
create table fact_sales(
sale_id int primary key,
customer_id int not null,
product_id int not null,
branch_id int not null,
quantity int,
sale_date date,
total_amount number(10,2),

foreign key(customer_id) references dim_customers(customer_id),
foreign key(product_id) references dim_products(product_id),
foreign key(branch_id) references dim_branches(branch_id)
);
create table fact_new_sales(
sale_id int primary key,
customer_id int not null,
product_id int not null,
branch_id int not null,
quantity int,
sale_date date,
total_amount number(10,2),

foreign key(customer_id) references dim_customers(customer_id),
foreign key(product_id) references dim_products(product_id),
foreign key(branch_id) references dim_branches(branch_id)
); 


copy into dim_customers
from @enterprise_stage
files=('customers.csv')
file_format=(format_name='csv_format');

copy into dim_products
from @enterprise_stage
files=('products.csv')
file_format=(format_name='csv_format');

copy into dim_branches
from @enterprise_stage
files=('branches.csv')
file_format=(format_name='csv_format');

copy into fact_sales
from @enterprise_stage
files=('sales.csv')
file_format=(format_name='csv_format');



-- 10.Create a Stream on the SALES table.
create stream sales_stream
on table fact_sales;

-- 11.Load new_sales.csv.
copy into fact_new_sales
from @enterprise_stage
files=('new_sales.csv')
file_format=(format_name='csv_format');

select*from fact_new_sales;

-- 12.Display only newly inserted records using the Stream.
-- 13.Merge newly arrived records into the SALES table
merge into fact_sales s
using fact_new_sales n
on s.sale_id=n.sale_id

when not matched then
insert(sale_id, customer_id, product_id, branch_id, quantity, sale_date, total_amount)
values(n.sale_id, n.customer_id, n.product_id, n.branch_id, n.quantity, n.sale_date, n.total_amount);

select*from sales_stream; 


-- 14.Identify duplicate Sale IDs.
select sale_id, count(*) as cnt from fact_sales
group by sale_id having
count(*)>1;

-- 15.Identify missing Customer IDs.
select s.* from fact_sales s
left join dim_customers c on 
s.customer_id=c.customer_id
where c.customer_id is NULL;

-- 16.Display invalid Product IDs.
select s.* from fact_sales s
left join dim_products p on 
s.product_id=p.product_id
where p.product_id is NULL;


-- 17.Count total newly inserted records.
select count(*) as cnt from fact_new_sales;



-- 18.Delete one sales record.
delete from fact_sales
where sale_id=3;
-- 19.Recover the deleted record using Time Travel.
insert into fact_sales 
select*from fact_sales at(offset=>-60*5) where sale_id=3;
-- 20.Verify recovery.
select*from fact_sales;


-- 21.Create a clone named: SALES_TEST
create table sales_test
clone fact_sales;

-- 22.Display cloned records.
select * from sales_test;
-- 23.Insert one new record into the clone.
insert into sales_test
values(16,1,101,1,2,'2026-07-05',12000);
-- 24.Verify that the original SALES table remains unchanged.
select*from fact_sales;


-- 25.Create a Task that automatically performs incremental loading every day.
create task auto_increment_load
warehouse=enterprise_wh
schedule="USING CRON 0 1 * * * UTC"
as
copy into fact_sales
from @enterprise_stage
files=('new_sales.csv')
file_format=(format_name='csv_format');
-- 26.Resume the Task.

alter task auto_increment_load
resume;
-- 27.Verify Task execution.
show tasks;


-- 28.Customer Revenue Report
select c.customer_id, c.customer_name, sum(s.total_amount) as revenue
from dim_customers c 
join fact_sales s on c.customer_id=s.customer_id
group by c.customer_id, c.customer_name
order by revenue desc;

-- 29.Branch Revenue Report
select b.branch_id, b.branch_name, sum(s.total_amount) as revenue
from dim_branches b 
join fact_sales s on b.branch_id=s.branch_id
group by b.branch_id, b.branch_name
order by revenue desc;


-- 30.Product Revenue Report
select p.product_id, p.product_name, sum(s.total_amount) as revenue
from dim_products p 
join fact_sales s on p.product_id=s.product_id
group by p.product_id, p.product_name
order by revenue desc;

-- 31.Monthly Revenue Report
select month(sale_date), sum(total_amount) as revenue
from fact_sales
group by month(sale_date)
order by revenue desc;

-- 32.Highest Revenue Customer
select customer_id, customer_name, sales from(select c.customer_id, c.customer_name, sum(s.total_amount) as sales,
rank() over(order by sales desc) as rnk
from dim_customers c 
join fact_sales s on c.customer_id=s.customer_id
group by c.customer_id, c.customer_name)t
where rnk=1;

-- 33.Highest Revenue Branch
select branch_id, branch_name, sales from (select b.branch_id, b.branch_name, sum(s.total_amount) as sales,
rank() over(order by sales desc) as rnk
from dim_branches b 
join fact_sales s on b.branch_id=s.branch_id
group by b.branch_id, b.branch_name)t where rnk=1;

-- 34.Top Five Products
select product_name, category,sales from (select p.product_name, p.category, sum(s.total_amount) as sales,
row_number() over(partition by p.category order by sales desc) as rnk
from dim_products p 
join fact_sales s on p.product_id=s.product_id
group by p.category,p.product_name)t where rnk<=5 order by sales desc;

-- 35.Customer Purchase Frequency
select c.customer_id, c.customer_name,
count(s.customer_id) as "purchase frequency"
from dim_customers c
join fact_sales s on c.customer_id=s.customer_id
group by c.customer_id, c.customer_name
order by "purchase frequency" desc, customer_id;

-- 36.Running Revenue
select sale_id, sale_date, total_amount,
sum(total_amount) over(order by sale_date,sale_id rows between unbounded preceding and current row) as running_total
from fact_sales
group by sale_id, sale_date,total_amount;

-- 37.Customer Ranking
select c.customer_id, c.customer_name, sum(s.total_amount) as sales,
rank() over(order by sales desc) as rnk
from dim_customers c 
join fact_sales s on c.customer_id=s.customer_id
group by c.customer_id, c.customer_name;


-- 38.Create View: CUSTOMER_REVENUE
create view customer_revenue as 
select c.customer_id, c.customer_name, sum(s.total_amount) as revenue
from dim_customers c 
join fact_sales s on c.customer_id=s.customer_id
group by c.customer_id, c.customer_name
order by revenue desc;

-- 39.Create Materialized View: BRANCH_REVENUE
create materialized view branch_revenue as
select branch_id, sum(total_amount) as revenue
from fact_sales 

group by branch_id;


-- 40.Display data from both Views.
select * from customer_revenue;

select * from branch_revenue;

