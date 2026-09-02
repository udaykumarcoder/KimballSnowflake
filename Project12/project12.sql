create warehouse omni_wh
with 
warehouse_size='xsmall'
auto_suspend=60
auto_resume=true;

use warehouse omni_wh;

create database RETAIL_DW;

use database RETAIL_DW;

-- show warehouses like 'omni_wh';
create schema SALES_ANALYTICS;

use schema SALES_ANALYTICS;

create file format csv_format
type = 'csv'
field_delimiter=','
skip_header=1;

create stage omni_stage;

create table DIM_STORE(
STORE_KEY NUMBER AUTOINCREMENT PRIMARY KEY,
STORE_ID NUMBER NOT NULL,
STORE_NAME VARCHAR(100),
CITY VARCHAR(50),
STATE VARCHAR(50),
STORE_MANAGER VARCHAR(100) 

);

create table DIM_PRODUCT(
PRODUCT_KEY NUMBER AUTOINCREMENT PRIMARY KEY,
PRODUCT_ID NUMBER,
PRODUCT_NAME VARCHAR(100),
CATEGORY VARCHAR(50),
UNIT_PRICE NUMBER(10,2)
);

create or replace table DIM_CUSTOMER_HYBRID(
CUSTOMER_KEY          NUMBER PRIMARY KEY AUTOINCREMENT  START 1 INCREMENT 1  , 
CUSTOMER_ID           NUMBER  NOT NULL   , 
CUSTOMER_NAME         VARCHAR(100), 
CITY                  VARCHAR(50) , 
PREVIOUS_CITY         VARCHAR(50) , 
STATE                 VARCHAR(50) , 
CURRENT_MEMBERSHIP    VARCHAR(30) , 
PREVIOUS_MEMBERSHIP   VARCHAR(30) , 
HISTORICAL_MEMBERSHIP VARCHAR(30) , 
SEGMENT               VARCHAR(30) , 
EFFECTIVE_DATE        DATE        , 
EXPIRY_DATE           DATE        , 
IS_CURRENT            BOOLEAN     
);

-- show primary keys in table DIM_CUSTOMER_HYBRID;

create table customers_initial(
CUSTOMER_ID           NUMBER  PRIMARY KEY , 
CUSTOMER_NAME         VARCHAR(100), 
CITY                  VARCHAR(50) , 
STATE                 VARCHAR(50) , 
MEMBERSHIP            VARCHAR(30) , 
SEGMENT               VARCHAR(30)
);

create table customer_updates(
CUSTOMER_ID           NUMBER  PRIMARY KEY , 
CUSTOMER_NAME         VARCHAR(100), 
CITY                  VARCHAR(50) , 
STATE                 VARCHAR(50) , 
MEMBERSHIP            VARCHAR(30) , 
SEGMENT               VARCHAR(30),
EFFECTIVE_DATE        DATE
);

copy into dim_store(store_id,store_name,city,state,store_manager)
from @omni_stage/stores.csv
file_format=(format_name=csv_format);

copy into dim_product(product_id, product_name, category, unit_price)
from @omni_stage/products.csv
file_format=(format_name=csv_format);

copy into customers_initial
from @omni_stage/customers_initial.csv
file_format=(format_name=csv_format);

copy into customer_updates
from @omni_stage/customer_updates.csv
file_format=(format_name=csv_format);

-- select * from dim_store;
-- select * from dim_product;
select * from customers_initial;

insert into DIM_CUSTOMER_HYBRID(
CUSTOMER_ID           , 
CUSTOMER_NAME         , 
CITY                  , 
PREVIOUS_CITY         , 
STATE                 , 
CURRENT_MEMBERSHIP    , 
PREVIOUS_MEMBERSHIP   , 
HISTORICAL_MEMBERSHIP , 
SEGMENT               , 
EFFECTIVE_DATE, 
EXPIRY_DATE   , 
IS_CURRENT    
)
select CUSTOMER_ID,CUSTOMER_NAME,CITY,NULL,STATE,MEMBERSHIP,NULL,MEMBERSHIP,SEGMENT,'2026-01-01','9999-12-31',TRUE 
from customers_initial;

create or replace table FACT_SALES(
SALES_KEY NUMBER AUTOINCREMENT PRIMARY KEY,      
TRANSACTION_ID VARCHAR(50)  ,
TRANSACTION_DATE DATE, 
CUSTOMER_KEY NUMBER,    
STORE_KEY NUMBER ,      
PRODUCT_KEY NUMBER,       
QUANTITY NUMBER    ,   
UNIT_PRICE NUMBER(10,2), 
TOTAL_AMOUNT NUMBER(12,2),
FOREIGN KEY(CUSTOMER_KEY) REFERENCES DIM_CUSTOMER_HYBRID(CUSTOMER_KEY),
FOREIGN KEY(STORE_KEY) REFERENCES DIM_STORE(STORE_KEY),
FOREIGN KEY(PRODUCT_KEY) REFERENCES DIM_PRODUCT(PRODUCT_KEY)

);

show tables;

INSERT INTO FACT_SALES(
TRANSACTION_ID   ,
TRANSACTION_DATE , 
CUSTOMER_KEY ,    
STORE_KEY  ,      
PRODUCT_KEY ,       
QUANTITY ,   
UNIT_PRICE , 
TOTAL_AMOUNT 
)
SELECT 'TXN-1001','2026-02-15',c.customer_key,s.store_key,p.product_key,1,p.unit_price,1*p.unit_price
from DIM_CUSTOMER_HYBRID c cross join DIM_STORE s 
cross join DIM_PRODUCT p 
where c.customer_id=101
and p.product_id=501
and s.store_id=201

UNION ALL 

SELECT 'TXN-1002', '2026-03-10', c.customer_key, s.store_key, p.product_key, 2, p.unit_price, 2 * p.unit_price 
FROM dim_product p CROSS JOIN dim_store s CROSS JOIN dim_customer_hybrid c WHERE p.product_id = 502 
AND s.store_id = 203 AND c.customer_id = 103;


-- select * from fact_sales;

-- select * from dim_store;

update dim_store
set store_manager='Suresh Menon'
where store_id=201;

select * exclude store_key from dim_store where store_id=201;

select * from dim_customer_hybrid;
-- select * from customer_updates;

-- time travel template
-- drop table if exists dim_customer_hybrid_bad;
-- drop table if exists dim_customer_hybrid_restore;
-- select * from dim_customer_hybrid
-- before (
-- statement=>'01c6cbed-3203-437b-0017-e2960014453a'
-- )
-- order by customer_id;

-- create or replace table dim_customer_hybrid_restore
-- clone dim_customer_hybrid 
-- before (statement=>'01c6cbed-3203-437b-0017-e2960014453a');

-- select * from dim_customer_hybrid_restore;

-- alter table dim_customer_hybrid
-- rename to dim_customer_hybrid_bad;

-- alter table dim_customer_hybrid_restore
-- rename to dim_customer_hybrid;

-- select * from dim_customer_hybrid order by customer_id;



-- task 10
-- STEP 1: Expire existing active records
UPDATE DIM_CUSTOMER_HYBRID d
SET
    EXPIRY_DATE = DATEADD(DAY, -1, u.EFFECTIVE_DATE),
    IS_CURRENT = FALSE
FROM CUSTOMER_UPDATES u
WHERE d.CUSTOMER_ID = u.CUSTOMER_ID
  AND d.IS_CURRENT = TRUE;

-- STEP 2: Insert new SCD Type 2/6 versions
INSERT INTO DIM_CUSTOMER_HYBRID
(
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CITY,
    PREVIOUS_CITY,
    STATE,
    CURRENT_MEMBERSHIP,
    PREVIOUS_MEMBERSHIP,
    HISTORICAL_MEMBERSHIP,
    SEGMENT,
    EFFECTIVE_DATE,
    EXPIRY_DATE,
    IS_CURRENT
)
SELECT
    u.CUSTOMER_ID,
    u.CUSTOMER_NAME,
    u.CITY,
    d.CITY AS PREVIOUS_CITY,
    u.STATE,
    u.MEMBERSHIP AS CURRENT_MEMBERSHIP,
    d.CURRENT_MEMBERSHIP AS PREVIOUS_MEMBERSHIP,
    u.MEMBERSHIP AS HISTORICAL_MEMBERSHIP,
    u.SEGMENT,
    u.EFFECTIVE_DATE,
    '9999-12-31',
    TRUE
FROM CUSTOMER_UPDATES u
JOIN DIM_CUSTOMER_HYBRID d
    ON d.CUSTOMER_ID = u.CUSTOMER_ID
WHERE d.IS_CURRENT = FALSE
  AND d.EXPIRY_DATE = DATEADD(DAY, -1, u.EFFECTIVE_DATE);


UPDATE DIM_CUSTOMER_HYBRID d
SET
    CITY = c.CITY,
    STATE = c.STATE,
    CURRENT_MEMBERSHIP = c.CURRENT_MEMBERSHIP,
    PREVIOUS_MEMBERSHIP = c.PREVIOUS_MEMBERSHIP
FROM DIM_CUSTOMER_HYBRID c
WHERE d.CUSTOMER_ID = c.CUSTOMER_ID
  AND c.IS_CURRENT = TRUE;

-- select * from dim_customer_hybrid order by customer_key;

-- task 11

insert into fact_sales(transaction_id, transaction_date, customer_key, store_key, product_key, quantity, unit_price, total_amount)
select 'TXN-2001', '2026-04-15', c.customer_key, s.store_key, p.product_key, 2, p.unit_price, 2*p.unit_price
from dim_product p 
join dim_store s on s.store_id=201
join dim_customer_hybrid c on c.customer_id=101 
where p.product_id=503
and c.is_current=True;

select * from fact_sales;

SELECT *
FROM DIM_CUSTOMER_HYBRID
ORDER BY CUSTOMER_ID, EFFECTIVE_DATE;
-- select * from dim_customer_hybrid;
-- select * from dim_store;
-- select * from fact_sales;
-- select * from dim_product;

select s.TRANSACTION_ID, s.TRANSACTION_DATE , c.CUSTOMER_ID , c.CUSTOMER_NAME ,c.city as  CURRENT_CITY , c.historical_membership as MEMBERSHIP_AT_PURCHASE , c.segment as SEGMENT_AT_PURCHASE ,  st.STORE_NAME ,p.PRODUCT_NAME ,s.TOTAL_AMOUNT
from fact_sales s 
join dim_customer_hybrid c on c.customer_key=s.customer_key
join dim_product p on s.product_key=p.product_key
join dim_store st on st.store_key=s.store_key
where c.customer_id=101;



SELECT 'STORE DIMENSION RECORDS' AS METRIC,
       COUNT(*) AS VALUE
FROM DIM_STORE

UNION ALL

SELECT 'PRODUCT DIMENSION RECORDS' AS METRIC,
       COUNT(*) AS VALUE
FROM DIM_PRODUCT

UNION ALL

SELECT 'TOTAL CUSTOMER DIMENSION RECORDS' AS METRIC,
       COUNT(*) AS VALUE
FROM DIM_CUSTOMER_HYBRID

UNION ALL

SELECT 'CURRENT CUSTOMER RECORDS' AS METRIC,
       COUNT(*) AS VALUE
FROM DIM_CUSTOMER_HYBRID
WHERE IS_CURRENT = TRUE

UNION ALL

SELECT 'HISTORICAL CUSTOMER RECORDS' AS METRIC,
       COUNT(*) AS VALUE
FROM DIM_CUSTOMER_HYBRID
WHERE IS_CURRENT = FALSE

UNION ALL

SELECT 'FACT SALES TRANSACTIONS' AS METRIC,
       COUNT(*) AS VALUE
FROM FACT_SALES;
