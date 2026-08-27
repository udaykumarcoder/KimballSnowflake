-- create warehouse scd_wh 
-- with 
-- warehouse_size='xsmall'
-- auto_suspend=60
-- auto_resume=true ;

-- use warehouse scd_wh;

-- create database scd_db;
-- use database scd_db;

-- create schema scd_schema;
-- use schema scd_schema;


-- create file format csv_format
-- type=csv 
-- field_delimiter=','
-- skip_header=1;


-- drop stage scd_stage;
-- create stage scd_stage
-- file_format=csv_format;

-- list @scd_stage;

-- create table dim_customer(
-- customer_id int primary key not null,
-- customer_name varchar,
-- city varchar,
-- state varchar,
-- membership varchar, 
-- segment varchar
-- );


-- copy into dim_customer 
-- from @scd_stage/customers_initial.csv 
-- file_format=(format_name=csv_format);

-- -- task 4 load initial data
-- select * from dim_customer;


-- create stage scd_update_stage
-- file_format=csv_format;

-- create table dim_update_customer(
-- customer_id int primary key not null,
-- customer_name varchar,
-- city varchar,
-- state varchar,
-- membership varchar, 
-- segment varchar
-- );

-- copy into dim_update_customer
-- from @scd_update_stage/customer_updates.csv
-- file_format=(format_name=csv_format);

-- select * from dim_update_customer where customer_id=101;
-- select * from dim_customer where customer_id=101;



-- -- task 6 identifying changed customers 

-- select d.customer_id,d.customer_name as old_name,u.customer_name as new_name, 
-- d.city as old_city, u.city as new_city, d.state as old_state, u.state as new_state,
-- d.membership as old_membership, u.membership as new_membership, d.segment as old_segment,
-- u.segment as new_segment
-- from dim_customer d join dim_update_customer u 
-- on d.customer_id=u.customer_id
-- where d.customer_name<>u.customer_name or 
-- d.city <> u.city or 
-- d.state<>u.state or 
-- d.membership<>u.membership or 
-- d.segment <> u.segment
-- order by d.customer_id;


-- -- task 7 identify attribute changes 
-- select d.customer_id,'city' as attribute,
-- d.city as old_city,u.city as new_city
-- from dim_customer d join dim_update_customer u
-- on d.customer_id=u.customer_id 
-- where d.city<>u.city;

-- select d.customer_id,'state' as attribute,
-- d.state as old_state,u.state as new_state
-- from dim_customer d join dim_update_customer u
-- on d.customer_id=u.customer_id 
-- where d.state<>u.state;

-- select d.customer_id,'membership' as attribute,
-- d.membership as old_membership,u.membership as new_membership
-- from dim_customer d join dim_update_customer u
-- on d.customer_id=u.customer_id 
-- where d.membership<>u.membership;

-- select d.customer_id,'segment' as attribute,
-- d.segment as old_segment,u.segment as new_segment
-- from dim_customer d join dim_update_customer u
-- on d.customer_id=u.customer_id 
-- where d.segment<>u.segment;


-- -- task 8 demonstrate scd problem solution
-- select * from dim_customer;


-- alter table dim_customer
-- add column new_city varchar,
-- new_state varchar,
-- new_membership varchar,
-- new_segment varchar;

-- alter table dim_customer
-- rename column city to old_city;

-- alter table dim_customer
-- rename column state to old_state;

-- alter table dim_customer
-- rename column membership to old_membership;

-- alter table dim_customer
-- rename column segment to old_segment;

-- select * from dim_customer;


-- -- type 1 overwrite version
-- update dim_customer 
-- set 
-- new_city=old_city,
-- new_state=old_state,
-- new_membership=old_membership,
-- new_segment=old_segment;



-- ============================================================
-- PROJECT 8 : SLOWLY CHANGING DIMENSION
-- CUSTOMER PROFILE HISTORY ANALYSIS USING SNOWFLAKE
-- SCD TYPE 1 DEMONSTRATION
-- ============================================================


-- ============================================================
-- TASK 1 : CREATE WAREHOUSE, DATABASE AND SCHEMA
-- ============================================================

CREATE WAREHOUSE scd_wh
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

USE WAREHOUSE scd_wh;

CREATE DATABASE scd_db;
USE DATABASE scd_db;

CREATE SCHEMA scd_schema;
USE SCHEMA scd_schema;


-- ============================================================
-- TASK 2 : CREATE CUSTOMER DIMENSION
-- ============================================================

CREATE TABLE dim_customer (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR,
    city VARCHAR,
    state VARCHAR,
    membership VARCHAR,
    segment VARCHAR
);


-- ============================================================
-- TASK 3 : CREATE FILE FORMAT AND INITIAL DATA STAGE
-- ============================================================

CREATE OR REPLACE FILE FORMAT csv_format
TYPE = CSV
FIELD_DELIMITER = ','
SKIP_HEADER = 1;

CREATE OR REPLACE STAGE scd_stage
FILE_FORMAT = csv_format;

LIST @scd_stage;


-- ============================================================
-- LOAD customers_initial.csv
-- ============================================================

COPY INTO dim_customer
FROM @scd_stage/customers_initial.csv
FILE_FORMAT = (FORMAT_NAME = csv_format);


-- ============================================================
-- TASK 4 : DISPLAY INITIAL CUSTOMER DIMENSION
-- ============================================================

SELECT *
FROM dim_customer
ORDER BY customer_id;

SELECT COUNT(*) AS total_customers
FROM dim_customer;


-- ============================================================
-- TASK 5 : CREATE UPDATE STAGE AND STAGING TABLE
-- ============================================================

CREATE OR REPLACE STAGE scd_update_stage
FILE_FORMAT = csv_format;

CREATE TABLE customer_updates (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR,
    city VARCHAR,
    state VARCHAR,
    membership VARCHAR,
    segment VARCHAR
);


-- ============================================================
-- LOAD customer_updates.csv
-- ============================================================

COPY INTO customer_updates
FROM @scd_update_stage/customer_updates.csv
FILE_FORMAT = (FORMAT_NAME = csv_format);


-- Display update records
SELECT *
FROM customer_updates
ORDER BY customer_id;

SELECT COUNT(*) AS records_received
FROM customer_updates;


-- ============================================================
-- TASK 6 : IDENTIFY CHANGED CUSTOMERS
-- ============================================================

SELECT
    d.customer_id,
    d.city AS old_city,
    u.city AS new_city,
    d.membership AS old_membership,
    u.membership AS new_membership
FROM dim_customer d
JOIN customer_updates u
    ON d.customer_id = u.customer_id
WHERE d.city <> u.city
   OR d.state <> u.state
   OR d.membership <> u.membership
   OR d.segment <> u.segment
ORDER BY d.customer_id;


-- ============================================================
-- TASK 7 : IDENTIFY ATTRIBUTE CHANGES
-- ============================================================

SELECT
    d.customer_id,
    'CITY' AS attribute,
    d.city AS old_value,
    u.city AS new_value
FROM dim_customer d
JOIN customer_updates u
    ON d.customer_id = u.customer_id
WHERE d.city <> u.city

UNION ALL

SELECT
    d.customer_id,
    'STATE' AS attribute,
    d.state AS old_value,
    u.state AS new_value
FROM dim_customer d
JOIN customer_updates u
    ON d.customer_id = u.customer_id
WHERE d.state <> u.state

UNION ALL

SELECT
    d.customer_id,
    'MEMBERSHIP' AS attribute,
    d.membership AS old_value,
    u.membership AS new_value
FROM dim_customer d
JOIN customer_updates u
    ON d.customer_id = u.customer_id
WHERE d.membership <> u.membership

UNION ALL

SELECT
    d.customer_id,
    'SEGMENT' AS attribute,
    d.segment AS old_value,
    u.segment AS new_value
FROM dim_customer d
JOIN customer_updates u
    ON d.customer_id = u.customer_id
WHERE d.segment <> u.segment

ORDER BY customer_id, attribute;


-- ============================================================
-- TASK 8 : DEMONSTRATE SCD TYPE 1
-- OVERWRITE EXISTING CUSTOMER INFORMATION
-- ============================================================

MERGE INTO dim_customer d
USING customer_updates u
    ON d.customer_id = u.customer_id

WHEN MATCHED THEN
    UPDATE SET
        d.customer_name = u.customer_name,
        d.city          = u.city,
        d.state         = u.state,
        d.membership    = u.membership,
        d.segment       = u.segment;


-- ============================================================
-- TASK 9 : DISPLAY UPDATED DIMENSION
-- ============================================================

SELECT *
FROM dim_customer
ORDER BY customer_id;


-- ============================================================
-- TASK 10 : DEMONSTRATE HISTORICAL DATA LOSS
-- ============================================================

SELECT
    customer_id,
    customer_name,
    city,
    state,
    membership
FROM dim_customer
WHERE customer_id = 101;


-- ============================================================
-- TASK 11 : BUSINESS IMPACT ANALYSIS
-- ============================================================

SELECT
    101 AS customer_id,
    'CITY' AS attribute,
    'Hyderabad' AS historical_value,
    city AS current_value
FROM dim_customer
WHERE customer_id = 101

UNION ALL

SELECT
    101,
    'STATE',
    'Telangana',
    state
FROM dim_customer
WHERE customer_id = 101

UNION ALL

SELECT
    101,
    'MEMBERSHIP',
    'Silver',
    membership
FROM dim_customer
WHERE customer_id = 101;


-- ============================================================
-- FINAL RESULT:
--
-- CUSTOMER 101
-- BEFORE:
-- Hyderabad | Telangana | Silver
--
-- AFTER SCD TYPE 1:
-- Bengaluru | Karnataka | Gold
--
-- OLD VALUES ARE OVERWRITTEN.
-- HISTORICAL INFORMATION IS LOST.
-- ============================================================
