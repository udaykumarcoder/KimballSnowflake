create warehouse customers_whare
with
warehouse_size='XSMALL'
auto_suspend=60
auto_resume=TRUE
initially_suspended=True;

use warehouse customers_whare;

create database customers_dbase;
use customers_dbase;

create schema customers_sc;

use schema customers_sc;

create stage stage_cus;

create file format csv_format
type='csv'
field_delimiter=','
skip_header=1;

create table customers(
customer_id int primary key,
customer_name varchar(50),
city varchar(20),
state varchar(20),
membership varchar(20),
segment varchar(20)
);

create table customers_updates_table(
customer_id int primary key,
customer_name varchar(50),
city varchar(20),
state varchar(20),
membership varchar(20),
segment varchar(20),
effective_date date
);


copy into customers
from @stage_cus
files=('customers.csv')
file_format=(format_name='csv_format');

copy into customers_updates_table
from @stage_cus
files=('customers_updates.csv')
file_format=(format_name='csv_format');

select * from customers;

select*from customers_updates_table;


create table dim_customers_1(
customer_key int primary key autoincrement,
customer_id int not null,
customer_name varchar,
city varchar,
current_membership varchar,
previous_membership varchar default null 
);

insert into dim_customers_1
(customer_id,customer_name,city,current_membership)
select customer_id,customer_name,city,membership 
from customers;

select * from dim_customers_1;
select * from customers_updates_table;

merge into dim_customers_1 d 
using customers_updates_table c 
on d.customer_id = c.customer_id 
when matched then update set 
d.previous_membership=d.current_membership,
d.current_membership=c.membership;



select * from dim_customers_1 order by customer_key;
-- above was type 3  



create table dim_customers_2(
customer_key int primary key autoincrement,
customer_id int not null,
customer_name varchar(50),
city varchar,
state varchar,
current_membership varchar,
previous_membership varchar,
historical_membership varchar,
segment varchar,
effective_date date,
expiry_date date,
is_current boolean default True
);


insert into dim_customers_2(customer_id, customer_name, city, state, current_membership, previous_membership, historical_membership, segment,
effective_date, expiry_date)
select customer_id, customer_name, city, state, membership, null, membership, segment, '2026-01-01', '9999-12-31' from customers;



select * from dim_customers_2;

-- closes the old record 
merge into dim_customers_2 d 
using customers_updates_table c 
on d.customer_id = c.customer_id 
when matched then update set 
-- d.previous_membership = d.current_membership,
-- d.current_membership = c.membership,
d.expiry_date = c.effective_date-1,
d.is_current=False;

select * from dim_customers_2;


insert into dim_customers_2(customer_id, customer_name, city, state, current_membership, previous_membership, historical_membership,
segment, effective_date, expiry_date, is_current)
select c.customer_id, c.customer_name, c.city, c.state, c.membership, d.current_membership, c.membership, c.segment, c.effective_date,
'9999-12-31', TRUE
from customers_updates_table c
join dim_customers_2 d
    on c.customer_id = d.customer_id
where d.is_current = FALSE;


select*from dim_customers_2 order by customer_id;


-- Current Customer Report
select customer_id, customer_name, city, current_membership, previous_membership from dim_customers_2
where is_current=True 
order by customer_id;



-- Point-in-Time Historical Query: What was Customer 101's membership on March 15, 2026?
select customer_key, customer_id, customer_name, current_membership, effective_date, expiry_date
from dim_customers_2
where customer_id=101 and
'2026-03-15' between effective_date and expiry_date;
