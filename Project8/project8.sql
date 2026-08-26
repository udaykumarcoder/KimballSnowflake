create warehouse scd_wh 
with 
warehouse_size='xsmall'
auto_suspend=60
auto_resume=true ;

use warehouse scd_wh;

create database scd_db;
use database scd_db;

create schema scd_schema;
use schema scd_schema;


create file format csv_format
type=csv 
field_delimiter=','
skip_header=1;


drop stage scd_stage;
create stage scd_stage
file_format=csv_format;

list @scd_stage;

create table dim_customer(
customer_id int primary key not null,
customer_name varchar,
city varchar,
state varchar,
membership varchar, 
segment varchar
);


copy into dim_customer 
from @scd_stage/customers_initial.csv 
file_format=(format_name=csv_format);

-- task 4 load initial data
select * from dim_customer;


create stage scd_update_stage
file_format=csv_format;

create table dim_update_customer(
customer_id int primary key not null,
customer_name varchar,
city varchar,
state varchar,
membership varchar, 
segment varchar
);

copy into dim_update_customer
from @scd_update_stage/customer_updates.csv
file_format=(format_name=csv_format);

select * from dim_update_customer where customer_id=101;
select * from dim_customer where customer_id=101;



-- task 6 identifying changed customers 

select d.customer_id,d.customer_name as old_name,u.customer_name as new_name, 
d.city as old_city, u.city as new_city, d.state as old_state, u.state as new_state,
d.membership as old_membership, u.membership as new_membership, d.segment as old_segment,
u.segment as new_segment
from dim_customer d join dim_update_customer u 
on d.customer_id=u.customer_id
where d.customer_name<>u.customer_name or 
d.city <> u.city or 
d.state<>u.state or 
d.membership<>u.membership or 
d.segment <> u.segment
order by d.customer_id;


-- task 7 identify attribute changes 
select d.customer_id,'city' as attribute,
d.city as old_city,u.city as new_city
from dim_customer d join dim_update_customer u
on d.customer_id=u.customer_id 
where d.city<>u.city;

select d.customer_id,'state' as attribute,
d.state as old_state,u.state as new_state
from dim_customer d join dim_update_customer u
on d.customer_id=u.customer_id 
where d.state<>u.state;

select d.customer_id,'membership' as attribute,
d.membership as old_membership,u.membership as new_membership
from dim_customer d join dim_update_customer u
on d.customer_id=u.customer_id 
where d.membership<>u.membership;

select d.customer_id,'segment' as attribute,
d.segment as old_segment,u.segment as new_segment
from dim_customer d join dim_update_customer u
on d.customer_id=u.customer_id 
where d.segment<>u.segment;


-- task 8 demonstrate scd problem solution
select * from dim_customer;


alter table dim_customer
add column new_city varchar,
new_state varchar,
new_membership varchar,
new_segment varchar;

alter table dim_customer
rename column city to old_city;

alter table dim_customer
rename column state to old_state;

alter table dim_customer
rename column membership to old_membership;

alter table dim_customer
rename column segment to old_segment;

select * from dim_customer;


-- type 1 overwrite version
update dim_customer 
set 
new_city=old_city,
new_state=old_state,
new_membership=old_membership,
new_segment=old_segment;




