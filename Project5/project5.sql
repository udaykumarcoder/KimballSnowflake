-- phase 1

-- business process : Retail Sales Analytics 
-- Business Events : A customer purchases one or more products from a retail branch on specific date
-- Reports required:

-- Customer-wise Sales
-- Product-wise Revenue
-- Branch-wise Revenue
-- State-wise Revenue
-- Monthly/Quarterly Revenue
-- Top 10 Customers
-- Top 10 Products
-- Top 10 Branches
-- Category-wise Revenue
-- Customer Purchase Trend
-- Product/Branch Performance
-- Regional Sales
-- Sales Trend






-- Phase 2 identify fact table
-- fact table name : fact_sales
-- sale_id primary key
-- customer_id foreign key
-- product_id foreign key
-- branch_id foreign key
-- date_id foreign key
-- quantity measure
-- total_amount measure

-- Grain:

-- One record in FACT_SALES represents one product sold to one customer from one branch on one specific date.


-- DIMENSION tables
-- there are 4 dimension tables 

-- 1.dim_customer

-- customer_id pk,
-- customer_name,
-- city,
-- state,
-- membership

-- 2.dim_products

-- product_id pk,
-- product_name,
-- category,
-- brand,
-- price

-- 3.dim_branch

-- branch_id pk,
-- branch_name,
-- city,
-- state,
-- region,
-- manager_name

-- 4.dim_date

-- date_id pk,
-- date,
-- day,
-- day_name,
-- week_no,
-- month,
-- quarter,
-- year,
-- is_weekend


create warehouse wh_sales
with 
warehouse_size='XSMALL'
auto_suspend=60
auto_resume=TRUE
initially_suspended=True;

use warehouse wh_sales;

create database db_sales;

use db_sales;

create schema schema_sales;
use schema schema_sales;

create stage stage_sales;

create file format csv_format
type='csv'
field_delimiter=','
skip_header=1;

create table dim_customers(
customer_id int primary key,
customer_name varchar(100),
city varchar(50),
state varchar(50),
membership varchar(50)
);

create table dim_products(
product_id int primary key,
product_name varchar(100),
category varchar(50),
brand varchar(50),
price number(10,2)
);

create table dim_branches(
branch_id int primary key,
branch_name varchar(100),
city varchar(50),
state varchar(50),
region  varchar(50),
manager_name varchar(50)
);

create table dim_date(
date_id int primary key,
date date,
day int,
day_name varchar(50),
week_no int,
month varchar(20),
quarter varchar(5),
year int,
is_weekend boolean

);

create table fact_sales(
sale_id int primary key,
customer_id int not null,
product_id int not null,
branch_id int not null,
date_id int not null,
quantity int,
total_amount number(10,2),

foreign key(customer_id) references dim_customers(customer_id),
foreign key(product_id) references dim_products(product_id),
foreign key(branch_id) references dim_branches(branch_id),
foreign key(date_id) references dim_date(date_id)

);
copy into dim_customers
from @stage_sales
files=('customers.csv')
file_format=(format_name='csv_format');

copy into dim_products
from @stage_sales
files=('products.csv')
file_format=(format_name='csv_format');

copy into dim_branches
from @stage_sales
files=('branches.csv')
file_format=(format_name='csv_format');

copy into dim_date
from @stage_sales
files=('calendar.csv')
file_format=(format_name='csv_format');

copy into fact_sales
from @stage_sales
files=('sales.csv')
file_format=(format_name='csv_format');


-- Customer-wise Sales Report
select c.customer_id, c.customer_name, sum(s.total_amount) as sales
from dim_customers c 
join fact_sales s on c.customer_id=s.customer_id
group by c.customer_id, c.customer_name
order by sales desc;

-- Product-wise Revenue Report
select p.product_id, p.product_name, sum(s.total_amount) as revenue
from dim_products p 
join fact_sales s on p.product_id=s.product_id
group by p.product_id, p.product_name
order by revenue desc;

-- Branch-wise Revenue Report
select b.branch_id, b.branch_name, sum(s.total_amount) as sales
from dim_branches b 
join fact_sales s on b.branch_id=s.branch_id
group by b.branch_id, b.branch_name
order by sales desc;

-- State-wise Revenue Report
select b.state, sum(s.total_amount) as revenue
from dim_branches b
join fact_sales s on  b.branch_id=s.branch_id
group by b.state
order by revenue desc;

-- Monthly Revenue Report
select d.month, sum(s.total_amount) as revenue
from dim_date d
join fact_sales s on d.date_id=s.date_id
group by d.month
order by revenue desc;

-- Quarterly Revenue Report
select d.quarter, sum(s.total_amount) as revenue
from dim_date d
join fact_sales s on d.date_id=s.date_id
group by d.quarter
order by revenue desc;

-- Top 10 Customers
select customer_id, customer_name, sales from(select c.customer_id, c.customer_name, sum(s.total_amount) as sales,
rank() over(order by sales desc) as rnk
from dim_customers c 
join fact_sales s on c.customer_id=s.customer_id
group by c.customer_id, c.customer_name)t
where rnk<=10;

-- Top 10 Products
select product_name, category,sales from (select p.product_name, p.category, sum(s.total_amount) as sales,
row_number() over(partition by p.category order by sales desc) as rnk
from dim_products p 
join fact_sales s on p.product_id=s.product_id
group by p.category,p.product_name)t where rnk<=10;

-- Top 10 Performing Branches
select branch_id, branch_name, sales from (select b.branch_id, b.branch_name, sum(s.total_amount) as sales,
rank() over(order by sales desc) as rnk
from dim_branches b 
join fact_sales s on b.branch_id=s.branch_id
group by b.branch_id, b.branch_name)t where rnk<=10;

-- Category-wise Revenue
select p.category, sum(s.total_amount) as revenue
from dim_products p 
join fact_sales s on p.product_id=s.product_id
group by p.category
order by revenue desc;
