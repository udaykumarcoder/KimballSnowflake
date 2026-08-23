PROJECT-6:Enterprise Retail Data Warehouse Design using Snowflake Schema

Topic:4.1C – Snowflake Schema
------------------------------
Problem Statement

A multinational retail company has successfully designed and implemented a Star Schema for its Retail Data Warehouse. The Star Schema has significantly improved analytical query performance and simplified business reporting. However, as the business expanded across multiple regions and product categories, the management observed that several dimension tables contained redundant information, resulting in increased storage requirements and data duplication.

To improve data consistency, reduce redundancy, and maintain standardized master data, the organization has decided to redesign the Data Warehouse using the Snowflake Schema architecture.

The company receives daily sales transactions from retail branches located across India. The warehouse stores information related to customers, products, branches, and calendar data. Business analysts generate reports such as customer revenue, product performance, regional sales, monthly revenue, quarterly analysis, and branch-wise performance.

As a Data Warehouse Architect, your responsibility is to convert the existing Star Schema into a Snowflake Schema by normalizing the dimension tables while preserving the existing FACT_SALES table. You must identify normalization opportunities, create additional lookup tables, establish hierarchical relationships, and design a complete Snowflake Schema capable of supporting enterprise-level analytical reporting.

The organization provides the following datasets:

customers.csv
products.csv
branches.csv
calendar.csv
sales.csv


customers.csv:
-------------
customer_id,customer_name,city,state,membership
1,Amit Sharma,Hyderabad,Telangana,Gold
2,Priya Singh,Bangalore,Karnataka,Silver
3,Rahul Verma,Chennai,Tamil Nadu,Gold
4,Neha Patel,Ahmedabad,Gujarat,Silver
5,Arjun Gupta,Delhi,Delhi,Platinum
6,Kiran Kumar,Vijayawada,Andhra Pradesh,Gold
7,Suresh Reddy,Warangal,Telangana,Silver
8,Pooja Mehta,Mumbai,Maharashtra,Gold
9,Rohit Jain,Jaipur,Rajasthan,Silver
10,Divya Nair,Kochi,Kerala,Gold
11,Mohan Rao,Visakhapatnam,Andhra Pradesh,Silver
12,Anjali Das,Kolkata,West Bengal,Gold
13,Naveen Yadav,Lucknow,Uttar Pradesh,Silver
14,Sneha Iyer,Coimbatore,Tamil Nadu,Gold
15,Rakesh Mishra,Patna,Bihar,Platinum
16,Kavya Rani,Bhopal,Madhya Pradesh,Silver
17,Varun Kapoor,Chandigarh,Chandigarh,Gold
18,Swathi Rao,Mysore,Karnataka,Silver
19,Nikhil Joshi,Nagpur,Maharashtra,Gold
20,Meera Thomas,Thiruvananthapuram,Kerala,Platinum


products.csv
-------------
product_id,product_name,category,brand,price
101,Laptop,Electronics,Dell,65000
102,Smartphone,Electronics,Samsung,28000
103,Tablet,Electronics,Apple,45000
104,Monitor,Electronics,LG,18000
105,Smart Watch,Electronics,Apple,22000
106,Keyboard,Accessories,Logitech,1800
107,Mouse,Accessories,HP,900
108,Headphones,Accessories,Sony,3500
109,Speaker,Accessories,JBL,5500
110,Web Camera,Accessories,Logitech,4200
111,Printer,Office Equipment,HP,15000
112,Scanner,Office Equipment,Canon,12000
113,Projector,Office Equipment,Epson,48000
114,Router,Networking,TP-Link,3200
115,Network Switch,Networking,Cisco,12500
116,External SSD,Storage,Samsung,9500
117,Hard Disk,Storage,Seagate,6500
118,USB Pen Drive,Storage,SanDisk,1200
119,Power Bank,Mobile Accessories,Mi,1800
120,Wireless Charger,Mobile Accessories,Anker,2500


branches.csv
--------------
branch_id,branch_name,city,state,region,manager_name
1,Hyderabad Central,Hyderabad,Telangana,South,Rajesh Kumar
2,Bangalore Tech Park,Bangalore,Karnataka,South,Priya Nair
3,Chennai City Mall,Chennai,Tamil Nadu,South,Suresh Reddy
4,Mumbai Business Hub,Mumbai,Maharashtra,West,Anita Sharma
5,Delhi Connaught Place,Delhi,Delhi,North,Rahul Verma
6,Ahmedabad Plaza,Ahmedabad,Gujarat,West,Kiran Patel
7,Kolkata City Center,Kolkata,West Bengal,East,Subhash Das
8,Jaipur Pink Square,Jaipur,Rajasthan,North,Neha Gupta
9,Kochi Metro Mall,Kochi,Kerala,South,Arun Thomas
10,Lucknow Galleria,Lucknow,Uttar Pradesh,North,Vivek Mishra


calendar.csv
-----------
date_id,date,day,day_name,week_no,month,quarter,year,is_weekend
1,2026-07-01,1,Wednesday,27,July,Q3,2026,No
2,2026-07-02,2,Thursday,27,July,Q3,2026,No
3,2026-07-03,3,Friday,27,July,Q3,2026,No
4,2026-07-04,4,Saturday,27,July,Q3,2026,Yes
5,2026-07-05,5,Sunday,27,July,Q3,2026,Yes
6,2026-07-06,6,Monday,28,July,Q3,2026,No
7,2026-07-07,7,Tuesday,28,July,Q3,2026,No
8,2026-07-08,8,Wednesday,28,July,Q3,2026,No
9,2026-07-09,9,Thursday,28,July,Q3,2026,No
10,2026-07-10,10,Friday,28,July,Q3,2026,No
11,2026-07-11,11,Saturday,28,July,Q3,2026,Yes
12,2026-07-12,12,Sunday,28,July,Q3,2026,Yes
13,2026-07-13,13,Monday,29,July,Q3,2026,No
14,2026-07-14,14,Tuesday,29,July,Q3,2026,No
15,2026-07-15,15,Wednesday,29,July,Q3,2026,No
16,2026-07-16,16,Thursday,29,July,Q3,2026,No
17,2026-07-17,17,Friday,29,July,Q3,2026,No
18,2026-07-18,18,Saturday,29,July,Q3,2026,Yes
19,2026-07-19,19,Sunday,29,July,Q3,2026,Yes
20,2026-07-20,20,Monday,30,July,Q3,2026,No
21,2026-07-21,21,Tuesday,30,July,Q3,2026,No
22,2026-07-22,22,Wednesday,30,July,Q3,2026,No
23,2026-07-23,23,Thursday,30,July,Q3,2026,No
24,2026-07-24,24,Friday,30,July,Q3,2026,No
25,2026-07-25,25,Saturday,30,July,Q3,2026,Yes
26,2026-07-26,26,Sunday,30,July,Q3,2026,Yes
27,2026-07-27,27,Monday,31,July,Q3,2026,No
28,2026-07-28,28,Tuesday,31,July,Q3,2026,No
29,2026-07-29,29,Wednesday,31,July,Q3,2026,No
30,2026-07-30,30,Thursday,31,July,Q3,2026,No
31,2026-07-31,31,Friday,31,July,Q3,2026,No


sales.csv
------------
sale_id,customer_id,product_id,branch_id,date_id,quantity,total_amount
1,1,101,1,1,1,65000
2,2,102,2,2,2,56000
3,3,103,3,3,3,135000
4,4,104,4,4,4,72000
5,5,105,5,5,5,110000
6,6,106,6,6,1,1800
7,7,107,7,7,2,1800
8,8,108,8,8,3,10500
9,9,109,9,9,4,22000
10,10,110,10,10,5,21000
11,11,111,1,11,1,15000
12,12,112,2,12,2,24000
13,13,113,3,13,3,144000
14,14,114,4,14,4,12800
15,15,115,5,15,5,62500
16,16,116,6,16,1,9500
17,17,117,7,17,2,13000
18,18,118,8,18,3,3600
19,19,119,9,19,4,7200
20,20,120,10,20,5,12500
21,1,101,1,21,1,65000
22,2,102,2,22,2,56000
23,3,103,3,23,3,135000
24,4,104,4,24,4,72000
25,5,105,5,25,5,110000
26,6,106,6,26,1,1800
27,7,107,7,27,2,1800
28,8,108,8,28,3,10500
29,9,109,9,29,4,22000
30,10,110,10,30,5,21000
31,11,111,1,31,1,15000
32,12,112,2,1,2,24000
33,13,113,3,2,3,144000
34,14,114,4,3,4,12800
35,15,115,5,4,5,62500
36,16,116,6,5,1,9500
37,17,117,7,6,2,13000
38,18,118,8,7,3,3600
39,19,119,9,8,4,7200
40,20,120,10,9,5,12500
41,1,101,1,10,1,65000
42,2,102,2,11,2,56000
43,3,103,3,12,3,135000
44,4,104,4,13,4,72000
45,5,105,5,14,5,110000
46,6,106,6,15,1,1800
47,7,107,7,16,2,1800
48,8,108,8,17,3,10500
49,9,109,9,18,4,22000
50,10,110,10,19,5,21000
51,11,111,1,20,1,15000
52,12,112,2,21,2,24000
53,13,113,3,22,3,144000
54,14,114,4,23,4,12800
55,15,115,5,24,5,62500
56,16,116,6,25,1,9500
57,17,117,7,26,2,13000
58,18,118,8,27,3,3600
59,19,119,9,28,4,7200
60,20,120,10,29,5,12500
61,1,101,1,30,1,65000
62,2,102,2,31,2,56000
63,3,103,3,1,3,135000
64,4,104,4,2,4,72000
65,5,105,5,3,5,110000
66,6,106,6,4,1,1800
67,7,107,7,5,2,1800
68,8,108,8,6,3,10500
69,9,109,9,7,4,22000
70,10,110,10,8,5,21000
71,11,111,1,9,1,15000
72,12,112,2,10,2,24000
73,13,113,3,11,3,144000
74,14,114,4,12,4,12800
75,15,115,5,13,5,62500
76,16,116,6,14,1,9500
77,17,117,7,15,2,13000
78,18,118,8,16,3,3600
79,19,119,9,17,4,7200
80,20,120,10,18,5,12500
81,1,101,1,19,1,65000
82,2,102,2,20,2,56000
83,3,103,3,21,3,135000
84,4,104,4,22,4,72000
85,5,105,5,23,5,110000
86,6,106,6,24,1,1800
87,7,107,7,25,2,1800
88,8,108,8,26,3,10500
89,9,109,9,27,4,22000
90,10,110,10,28,5,21000
91,11,111,1,29,1,15000
92,12,112,2,30,2,24000
93,13,113,3,31,3,144000
94,14,114,4,1,4,12800
95,15,115,5,2,5,62500
96,16,116,6,3,1,9500
97,17,117,7,4,2,13000
98,18,118,8,5,3,3600
99,19,119,9,6,4,7200
100,20,120,10,7,5,12500


Business Requirements:
----------------------
The Snowflake Schema should support the following analytical reports:

Customer-wise Sales Report
Product-wise Revenue Report
Brand-wise Revenue Report
Category-wise Revenue Report
City-wise Sales Report
State-wise Revenue Report
Region-wise Revenue Report
Monthly Revenue Report
Quarterly Revenue Report
Top 10 Customers
Top 10 Products
Top 10 Branches
Customer Purchase Trend
Product Performance Dashboard
Regional Sales Dashboard

Your Tasks:
--------------
Phase-1: Analyze the Existing Star Schema
---------------------------------------------
Identify:
Fact Table
Dimension Tables
Measures
Relationships


Phase-2: Identify Redundant Attributes
----------------------------------------
Identify attributes that should be normalized.
Examples:
Customer
    State
    City
Product
    Brand
    Category
Branch
    Region
    State
    City
Date
    Month
    Quarter
    Year

Phase-3: Create Normalized Dimension Tables
--------------------------------------------
Design the following lookup tables:

Customer Hierarchy
DIM_STATE
DIM_CITY
Product Hierarchy
DIM_CATEGORY
DIM_BRAND
Branch Hierarchy
DIM_REGION
DIM_STATE
DIM_CITY
Date Hierarchy
DIM_YEAR
DIM_QUARTER
DIM_MONTH

Phase-4: Modify Existing Dimensions
-------------------------------------
Normalize
DIM_CUSTOMER
DIM_PRODUCT
DIM_BRANCH
DIM_DATE
using lookup tables.

Phase-5: Draw Snowflake Schema
--------------------------------
Design the complete Snowflake Schema showing
Fact Table
Dimension Tables
Lookup Tables
PK
FK
Hierarchical Relationships

Phase-6: Comparison
-----------------------
Compare
Star Schema vs Snowflake Schema
based on
    Storage
    Redundancy
    Query Performance
    Maintenance
    Complexity

Phase-7: Validation
---------------------
Explain how the Snowflake Schema supports

Customer Reports
Product Reports
Branch Reports
Revenue Reports
Regional Reports

Expected Outputs
-------------------
Output-1:Business Process
Retail Sales Analytics

Output-2:Business Event
-----------
A customer purchases one or more products from a retail branch on a specific date.

Output-3:Fact Table
------------------

Output-4:Normalized Dimension Tables
-------------
| Table        |
| ------------ |
| DIM_CUSTOMER |
| DIM_PRODUCT  |
| DIM_BRANCH   |
| DIM_DATE     |
| DIM_CITY     |
| DIM_STATE    |
| DIM_REGION   |
| DIM_CATEGORY |
| DIM_BRAND    |
| DIM_MONTH    |
| DIM_QUARTER  |
| DIM_YEAR     |


Output-5:Customer Hierarchy
-----------
DIM_STATE
      |
      |
DIM_CITY
      |
      |
DIM_CUSTOMER

Output-6:Product Hierarchy
-----------
DIM_CATEGORY
       |
       |
DIM_BRAND
       |
       |
DIM_PRODUCT

Output-7:Branch Hierarchy
-------------
DIM_REGION
      |
DIM_STATE
      |
DIM_CITY
      |
DIM_BRANCH

Output-8:Date Hierarchy
---------
DIM_YEAR
    |
DIM_QUARTER
    |
DIM_MONTH
    |
DIM_DATE

Output-9:Snowflake Schema Relationships
-----------
FACT_SALES ---- DIM_CUSTOMER

FACT_SALES ---- DIM_PRODUCT

FACT_SALES ---- DIM_BRANCH

FACT_SALES ---- DIM_DATE

DIM_CUSTOMER ---- DIM_CITY

DIM_CITY ---- DIM_STATE

DIM_PRODUCT ---- DIM_BRAND

DIM_BRAND ---- DIM_CATEGORY

DIM_BRANCH ---- DIM_CITY

DIM_CITY ---- DIM_STATE

DIM_STATE ---- DIM_REGION

DIM_DATE ---- DIM_MONTH

DIM_MONTH ---- DIM_QUARTER

DIM_QUARTER ---- DIM_YEAR

Output-10:Complete Snowflake Schema
----------
                         DIM_CATEGORY
                               |
                         DIM_BRAND
                               |
                          DIM_PRODUCT
                               |
                               |
DIM_REGION--DIM_STATE--DIM_CITY--DIM_BRANCH
                               |
                               |
                        FACT_SALES
                               |
                               |
DIM_STATE--DIM_CITY--DIM_CUSTOMER
                               |
                               |
DIM_YEAR--DIM_QUARTER--DIM_MONTH--DIM_DATE


Output-11:Star Schema vs Snowflake Schema
----------
| Feature           | Star Schema | Snowflake Schema      |
| ----------------- | ----------- | --------------------- |
| Normalization     | No          | Yes                   |
| Storage           | Higher      | Lower                 |
| Redundancy        | More        | Less                  |
| Query Performance | Faster      | Slightly Slower       |
| Maintenance       | Moderate    | Easier                |
| Joins             | Fewer       | More                  |
| Best Suitable For | Reporting   | Enterprise Warehouses |


Output-12:Advantages of Snowflake Schema
----------
• Eliminates redundant data.
• Reduces storage requirements.
• Improves data consistency.
• Simplifies master data management.
• Supports complex enterprise reporting.
• Ideal for large-scale data warehouses.


Output-13:Learning Outcomes
Students will be able to:

Convert a Star Schema into a Snowflake Schema.
Normalize dimension tables.
Create hierarchical lookup tables.
Reduce data redundancy.
Design enterprise-scale data warehouse schemas.
Compare Star Schema and Snowflake Schema.
Select an appropriate schema based on business requirements.



Concepts Covered:
-------------------
Snowflake Schema
Dimension Normalization
Lookup Tables
Hierarchies
Primary Keys
Foreign Keys
Fact Table
Dimension Tables
Data Redundancy
Storage Optimization
Enterprise Data Warehouse Design
Star Schema vs Snowflake Schema Comparison











create warehouse mnc_wh
with 
warehouse_size='xsmall'
auto_suspend=60
auto_resume=True 
initially_suspended=true ;

use warehouse mnc_wh;

create database mnc_db;

use database mnc_db;

create schema mnc_schema;

use schema mnc_schema;

create stage mnc_stage;

create file format csv_format
type='csv'
field_delimiter=','
skip_header=1;

list @mnc_stage;

create table customers(
customer_id int primary key,
customer_name varchar(100),
city varchar(50),
state varchar(50),
membership varchar(50)
);

create table products(
product_id int primary key,
product_name varchar(100),
category varchar(50),
brand varchar(50),
price number(10,2)
);

create table t_branches(
branch_id int primary key,
branch_name varchar(100),
city varchar(50),
state varchar(50),
region  varchar(50),
manager_name varchar(50)
);

create table t_date(
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

create table sales(
sale_id int primary key,
customer_id int not null,
product_id int not null,
branch_id int not null,
date_id int not null,
quantity int,
total_amount number(10,2),

foreign key(customer_id) references customers(customer_id),
foreign key(product_id) references products(product_id),
foreign key(branch_id) references t_branches(branch_id),
foreign key(date_id) references t_date(date_id)

);

copy into customers
from @mnc_stage
files=('customers.csv')
file_format=(format_name='csv_format');

copy into products
from @mnc_stage
files=('products.csv')
file_format=(format_name='csv_format');

copy into t_branches
from @mnc_stage
files=('branches.csv')
file_format=(format_name='csv_format');

copy into t_date
from @mnc_stage
files=('calendar.csv')
file_format=(format_name='csv_format');

copy into sales
from @mnc_stage
files=('sales.csv')
file_format=(format_name='csv_format');


-- creating dimension tables 
create table dim_state(
state_id int primary key autoincrement,
state_name varchar(50)
);

create table dim_city (
city_id int primary key autoincrement,
city_name varchar(50),
state_id int not null ,
foreign key(state_id) references dim_state(state_id)
);

create table dim_customers(
customer_id int primary key,
customer_name varchar(100),
membership varchar(50),
city_id int not null,
foreign key(city_id) references dim_city(city_id)
);



create table dim_category(
category_id int primary key autoincrement,
category_name varchar(50)
);

create table dim_brand(
brand_id int primary key autoincrement,
brand_name varchar(50)

);



create table dim_products(
product_id int primary key,
product_name varchar(100),
price number(10,2),
brand_id int not null,
category_id int not null,

foreign key(brand_id) references dim_brand(brand_id),
foreign key(category_id) references dim_category(category_id)
);

create table dim_region (
region_id int primary key autoincrement,
region_name varchar(50)
);

alter table dim_state 
add region_id int not null ;

alter table dim_state 
add foreign key(region_id) references dim_region(region_id);

create table dim_branches(
branch_id int primary key,
branch_name varchar(100),
manager_name varchar(50),
city_id int not null,
foreign key(city_id) references dim_city(city_id)
);

create table dim_year(
year_id int primary key autoincrement,
year int
);

create table dim_quarter(
quarter_id int primary key autoincrement,
quarter varchar(5),
year_id int not null
);


create table dim_quarter(
quarter_id int primary key autoincrement,
quarter varchar(5),
year_id int not null,

constraint uk_quarter unique(quarter, year_id),

foreign key(year_id) references dim_year(year_id)
);



create table dim_month(
month_id int primary key autoincrement,
month_name varchar(20),
quarter_id int not null,

constraint uk_month unique(month_name, quarter_id),

foreign key(quarter_id) references dim_quarter(quarter_id)
);

create table dim_date(
date_id int primary key,
date date,
day int,
day_name varchar(50),
week_no int,
is_weekend boolean,
month_id int not null,

foreign key(month_id) references dim_month(month_id)
);


alter table sales
rename to fact_sales;

insert into dim_region(region_name)
select distinct region from t_branches;

select * from dim_region;

insert into dim_state(state_name,region_id)
select distinct b.state,r.region_id
from t_branches b 
join dim_region r 
on b.region=r.region_name;


select * from dim_state;

insert into dim_city(city_name,state_id)
select distinct b.city,s.state_id
from t_branches b join 
dim_state s on 
b.state=s.state_name;

select * from dim_city;

insert into dim_branches
(branch_id,branch_name,manager_name,city_id)
select t.branch_id,t.branch_name,t.manager_name,
c.city_id
from t_branches t 
join dim_state s on t.state=s.state_name 
join dim_city c on t.city=c.city_name 
and c.state_id = s.state_id;

select * from dim_branches;

insert into dim_category(category_name)
select distinct category from products;

select*from dim_category;

insert into dim_brand(brand_name)
select distinct p.brand from products p;

insert into dim_products(product_id, product_name, price, brand_id, category_id)
select p.product_id, p.product_name, p.price, b.brand_id, c.category_id
from products p 
join dim_category c on p.category=c.category_name
join dim_brand b on p.brand=b.brand_name;

insert into dim_customers(customer_id, customer_name, membership, city_id)
select c.customer_id, c.customer_name, c.membership, d.city_id
from customers c 
join dim_state s on c.state=s.state_name
join dim_city d on c.city=d.city_name
and s.state_id=d.state_id;

select * from dim_customers;




insert into dim_year(year)
select distinct year from t_date;

select*from dim_year;

insert into dim_quarter(quarter, year_id)
select distinct d.quarter, y.year_id
from t_date d
join dim_year y on d.year=y.year;

select*from dim_quarter;

insert into dim_month(month_name, quarter_id)
select distinct d.month, q.quarter_id from 
t_date d
join dim_year y on d.year=y.year
join dim_quarter q on d.quarter=q.quarter
and q.year_id=y.year_id;

select*from dim_month;

insert into dim_date(date_id, date, day, day_name, week_no, is_weekend, month_id)
select d.date_id, d.date, d.day, d.day_name, d.week_no, d.is_weekend, m.month_id
from t_date d
join dim_year y on d.year=y.year
join dim_quarter q on d.quarter=q.quarter
and q.year_id=y.year_id
join dim_month m on d.month=m.month_name
and m.quarter_id=q.quarter_id;

select*from dim_date;



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

-- Brand-wise Revenue Report
select b.brand_id, b.brand_name, sum(s.total_amount) as revenue
from dim_brand b
join dim_products p on b.brand_id=p.brand_id
join fact_sales s on p.product_id=s.product_id
group by b.brand_id, b.brand_name
order by revenue desc;

-- Category-wise Revenue Report
select c.category_id, c.category_name, sum(s.total_amount) as revenue
from dim_category c
join dim_products p on c.category_id=p.category_id
join fact_sales s on p.product_id=s.product_id
group by c.category_id, c.category_name
order by revenue desc;

-- City-wise Sales Report
select c.city_id, c.city_name, sum(s.total_amount) as sales
from dim_city c
join dim_customers cu on c.city_id=cu.city_id
join fact_sales s on cu.customer_id=s.customer_id
group by c.city_id, c.city_name
order by sales desc;

-- State-wise Revenue Report
select st.state_id, st.state_name, sum(s.total_amount) as revenue
from dim_state st
join dim_city ci on st.state_id=ci.state_id
join dim_customers c on ci.city_id=c.city_id
join fact_sales s on c.customer_id=s.customer_id
group by st.state_id, st.state_name
order by revenue desc;

-- Region-wise Revenue Report
select r.region_id, r.region_name, sum(s.total_amount) as revenue
from dim_region r
join dim_state st on r.region_id=st.region_id
join dim_city ci on st.state_id=ci.state_id
join dim_branches b on ci.city_id=b.city_id
join fact_sales s on b.branch_id=s.branch_id
group by r.region_id, r.region_name
order by revenue desc;

-- Monthly Revenue Report
select m.month_id, m.month_name, sum(s.total_amount) as revenue
from dim_month m 
join dim_date d on m.month_id=d.month_id
join fact_sales s on d.date_id=s.date_id
group by m.month_id, m.month_name
order by revenue desc;

-- Quarterly Revenue Report
select q.quarter_id, q.quarter, sum(s.total_amount) as revenue
from dim_quarter q 
join dim_month m on q.quarter_id=m.quarter_id
join dim_date d on m.month_id=d.month_id
join fact_sales s on d.date_id=s.date_id
group by q.quarter_id, q.quarter
order by revenue desc;

-- Top 10 Customers
select customer_id, customer_name, sales from (select c.customer_id, c.customer_name, sum(s.total_amount) as sales,
dense_rank() over(order by sales desc) as rnk
from dim_customers c
join fact_sales s on c.customer_id=s.customer_id
group by c.customer_id, c.customer_name)t where rnk<=10;

-- Top 10 Products
select product_id, product_name, revenue from (select p.product_id, p.product_name, sum(s.total_amount) as revenue,
dense_rank() over(order by revenue desc) as rnk
from dim_products p
join fact_sales s on p.product_id=s.product_id
group by p.product_id, p.product_name)t where rnk<=10;

-- Top 10 Branches
select branch_id, branch_name, revenue from (select b.branch_id, b.branch_name, sum(s.total_amount) as revenue,
dense_rank() over(order by revenue desc) as rnk
from dim_branches b 
join fact_sales s on b.branch_id=s.branch_id
group by b.branch_id, b.branch_name)t where rnk<=10;
