Problem Statement:
-----------------
A nationwide retail chain has expanded its operations across multiple
cities and now receives daily sales data from all its branches. 
To improve reporting and decision-making, the company has migrated its data to the Snowflake Cloud Data Warehouse.

Every day, the company receives four CSV files containing customer details, product information, branch information, and sales transactions. The data engineering team must load these files into Snowflake, while the business intelligence team needs analytical reports to identify top-performing products, branches, and customers.

Your task is to build the Snowflake environment, load the data, and generate business reports that help management understand sales trends and customer purchasing behavior.

Project Objectives:
---------------------
After completing this project, students will be able to:

Load multiple datasets into Snowflake.
Perform multi-table joins.
Use aggregate functions.
Apply Window Functions.
Use Common Table Expressions (CTEs).
Create Views and Materialized Views.
Generate business intelligence reports.

Input Files:
------------
The company provides the following CSV files:

customers.csv
products.csv
branches.csv
sales.csv


customers.csv
--------------
customer_id,customer_name,city,membership
1,Amit,Hyderabad,Gold
2,Priya,Bengaluru,Silver
3,Rahul,Chennai,Gold
4,Neha,Pune,Silver
5,Arjun,Delhi,Platinum


products.csv
------------
product_id,product_name,category,price
101,Laptop,Electronics,60000
102,Mobile,Electronics,25000
103,Headphones,Accessories,3000
104,Keyboard,Accessories,1500
105,Monitor,Electronics,12000


branches.csv
-------------
branch_id,branch_name,city
1,Hyderabad Branch,Hyderabad
2,Bengaluru Branch,Bengaluru
3,Delhi Branch,Delhi


sales.csv
----------
sale_id,customer_id,product_id,branch_id,quantity,sale_date,total_amount
1,1,101,1,1,2026-07-01,60000
2,2,102,2,2,2026-07-02,50000
3,3,103,2,3,2026-07-03,9000
4,4,104,1,5,2026-07-04,7500
5,5,105,3,2,2026-07-05,24000
6,1,102,1,1,2026-07-06,25000
7,2,105,2,1,2026-07-07,12000
8,3,101,3,1,2026-07-08,60000
9,4,103,1,2,2026-07-09,6000
10,5,102,3,1,2026-07-10,25000
11,1,104,1,4,2026-07-11,6000
12,2,103,2,2,2026-07-12,6000


Your Tasks:
-----------
Phase-1: Snowflake Environment
-------------------------------
Create a Warehouse named RETAIL_WH.
Create a Database named RETAIL_DB.
Create a Schema named SALES_SCHEMA.
Create a CSV File Format.
Create an Internal Stage.


Phase-2: Data Loading
----------------------
Upload all four CSV files.
Create the required tables.
Load the data using COPY INTO.
Verify the imported records.

Phase-3: SQL Analytics
-------------------------
Display all customers.
Display all products.
Display all branches.
Display all sales transactions.
Calculate total business revenue.
Generate customer-wise sales.
Generate branch-wise sales.
Generate product-wise sales.
Generate category-wise sales.
Display the highest revenue branch.
Display the highest spending customer.
Display the top three products by revenue.
Display the top three customers by spending.


Phase-4: Window Functions
---------------------------
Rank customers based on total spending.
Rank branches based on total sales.
Display the top-selling product in each category using ROW_NUMBER().
Calculate cumulative sales using SUM() OVER().
Calculate the average sale amount using AVG() OVER().


Phase-5: CTE
--------------
Generate customer-wise revenue using a Common Table Expression (CTE).
Display customers whose spending is greater than the average spending.


Phase-6: Views
-----------------
Create a View named SALES_REPORT.
Create a Materialized View named TOP_CUSTOMERS.
Query both views.



Expected Outputs:
-------------
You should generate the following reports:
All Customers
All Products
All Branches
Customer-wise Sales Report
Branch-wise Revenue Report
Product-wise Revenue Report
Category-wise Revenue Report
Highest Revenue Branch
Highest Spending Customer
Top Three Products
Top Three Customers
Customer Ranking
Branch Ranking
Top Product in Each Category
Cumulative Sales Report
Average Sales Report
Customers Spending Above Average
Sales Report View
Materialized View Report



*/

select current_role();

create resource monitor credits_limit
with credit_quota=1
triggers
on 10 percent do notify
on 15 percent do suspend_immediate;

create warehouse RETAIL_WH
with 
warehouse_size = 'xsmall'
auto_suspend = 60
auto_resume=TRUE
initially_suspended=TRUE;;

use warehouse RETAIL_WH;

ALTER WAREHOUSE RETAIL_WH
SET RESOURCE_MONITOR = CREDITS_LIMIT;


create database RETAIL_DB;

use database RETAIL_DB;

create schema SALES_SCHEMA;

use schema SALES_SCHEMA;

create file format csv_format
type = 'CSV'
field_delimiter=','
skip_header=1;

create stage RETAIL_STAGE
file_format = csv_format;

create table Customers(
customer_id int unique not null,
customer_name varchar(55) not null,
city varchar(55),
membership varchar(50) 
);
create table Products(
product_id int unique not null,
product_name varchar(50),
category varchar(50),
price int 
);


create table Branches(
branches_id int unique not null,
branch_name varchar(55),
city varchar(55)
);

create table Sales(
sale_id int unique not null,
customer_id int,
product_id int,
branches_id int ,
quantity int ,
sale_date date,
total_amount decimal(10,2),
);

alter table Sales 
add constraint fk_sales_customer
foreign key (customer_id)
references Customers(customer_id);

alter table Sales 
add constraint fk_sales_product 
foreign key (product_id)
references Products(product_id);

alter table Sales 
add constraint fk_sales_branches
foreign key (branches_id)
references Branches(branches_id);



-- show imported keys in table Sales;

copy into Customers 
from @RETAIL_STAGE/customers.csv;

copy into Products
from @RETAIL_STAGE/products.csv;

copy into Branches
from @RETAIL_STAGE/branches.csv;

copy into Sales 
from @RETAIL_STAGE/sales.csv;

select * from Customers;
select * from Products;
select * from Branches;
select * from Sales;


-- total business revenue

select sum(total_amount) from Sales;

-- generate customer_wise sales 

alter resource monitor credits_limit
set credit_quota=10;



select c.customer_name , sum(s.total_amount) as total_sales from Customers c join Sales s
on c.customer_id=s.customer_id 
group by c.customer_name;


-- branch wise sales 

select b.branch_name, sum(s.total_amount)
from BRANCHES b join Sales s 
on b.branches_id=s.branches_id
group by b.branch_name;


-- product wise sales 

select p.product_id,p.product_name,sum(s.total_amount) from Sales s join Products p
on p.product_id=s.product_id
group by p.product_id,p.product_name;

-- category wise sales 

select p.category,sum(s.total_amount)
from Sales s join Products p 
on s.product_id=p.product_id
group by p.category;

-- highest rev branch
select b.branch_name, sum(s.total_amount) as bsales
from BRANCHES b join Sales s 
on b.branches_id=s.branches_id
group by b.branch_name
order by bsales desc limit 1;


-- highest spending customer 
select c.customer_name , sum(s.total_amount) as total_sales from Customers c join Sales s
on c.customer_id=s.customer_id 
group by c.customer_name
order by total_sales desc limit 1;

-- top 3 products by revenue 
select p.product_id,p.product_name,sum(s.total_amount) as ps from Sales s join Products p
on p.product_id=s.product_id
group by p.product_id,p.product_name
order by ps desc limit 3;


-- top 3 customers by spending 
select c.customer_name , sum(s.total_amount) as total_sales from Customers c join Sales s
on c.customer_id=s.customer_id 
group by c.customer_name
order by total_sales desc limit 3;



-- rank customers based on total_spending 
select c.customer_name , sum(s.total_amount) as total_sales,
rank() over(order by total_sales desc)
from Customers c join Sales s
on c.customer_id=s.customer_id 
group by c.customer_name;


-- branch wise rank 
select b.branch_name, sum(s.total_amount) as bs, 
rank() over(order by bs desc )
from BRANCHES b join Sales s 
on b.branches_id=s.branches_id
group by b.branch_name;


-- Display the top-selling product in each category using ROW_NUMBER().
select p.product_name,p.category,sum(s.total_amount) as ps,
row_number() over(partition by p.category order by ps desc) as rnk
from Sales s join Products p
on p.product_id=s.product_id
group by p.category,p.product_name
qualify rnk=1;


-- Calculate cumulative sales using SUM() OVER().

select sale_id,total_amount, sum(total_amount) over(order by sale_id) as cumulative_sum
from Sales;


-- Calculate the average sale amount using AVG() OVER().

select sale_id,total_amount, avg(total_amount) over() as cumulative_sum
from Sales;


-- Generate customer-wise revenue using a Common Table Expression (CTE).
WITH customer_sales AS (
    SELECT
        c.customer_name,
        SUM(s.total_amount) AS total_sales
    FROM Customers c
    JOIN Sales s
        ON c.customer_id = s.customer_id
    GROUP BY c.customer_name
)
SELECT *
FROM customer_sales;


-- Display customers whose spending is greater than the average spending.
WITH customer_spending AS (
    SELECT
        customer_id,
        SUM(total_amount) AS total_spending
    FROM Sales
    GROUP BY customer_id
),
average_spending AS (
    SELECT
        AVG(total_spending) AS avg_spending
    FROM customer_spending
)
SELECT
    c.customer_id,
    c.customer_name,
    cs.total_spending
FROM Customers c
JOIN customer_spending cs
    ON c.customer_id = cs.customer_id
CROSS JOIN average_spending a
WHERE cs.total_spending > a.avg_spending;



CREATE VIEW SALES_REPORT AS
SELECT
    c.customer_id,
    c.customer_name,
    c.city,
    c.membership,
    SUM(s.total_amount) AS total_sales
FROM Customers c
JOIN Sales s
    ON c.customer_id = s.customer_id
GROUP BY
    c.customer_id,
    c.customer_name,
    c.city,
    c.membership;

SELECT *
FROM SALES_REPORT;


CREATE MATERIALIZED VIEW TOP_CUSTOMERS AS
SELECT
    customer_id,
    SUM(total_amount) AS total_sales
FROM Sales
GROUP BY customer_id;

SELECT
    c.customer_id,
    c.customer_name,
    t.total_sales
FROM TOP_CUSTOMERS t
JOIN Customers c
    ON c.customer_id = t.customer_id
ORDER BY t.total_sales DESC;
