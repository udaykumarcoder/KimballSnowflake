create warehouse ecommerce_wh
with 
warehouse_size='XSMALL'
auto_suspend=60
auto_resume=true
initially_suspended=True;

use warehouse ecommerce_wh;

create database ecommerce_db;
use ecommerce_db;

create schema ecommerce_schema;
use schema ecommerce_schema;

create file format json_format 
type = 'json';

create stage raw_events;

create or replace table raw_json_landing(
raw_data variant
);

create table lake_raw_events(
raw_data variant
);

create or replace table quarantine_raw_events(
quarantine_id integer primary key autoincrement start 1 increment 1,
raw_record_text varchar,
reason varchar 
);

copy into raw_json_landing
from @raw_events
file_format=(format_name='json_format')
on_error='continue';

-- all data 
select count(*) from raw_json_landing;

-- inspect raw landing data types 
select raw_data, typeof(raw_data)
from raw_json_landing
order by raw_data:event_id;

-- quarantine the invalid record 

insert into quarantine_raw_events
(
raw_record_text,
reason
)
select raw_data::varchar as raw_record_text,
'MALFORMED_JSON_BODY' as reason
from raw_json_landing
where raw_data:event_id::varchar='INVALID_JSON_PAYLOAD_MALFORMED_STRING';


-- inserting only valid data 
insert into lake_raw_events
(
raw_data
)
select raw_data
from raw_json_landing 
where raw_data:event_id::varchar<>'INVALID_JSON_PAYLOAD_MALFORMED_STRING';


-- task 1
select count(*) from lake_raw_events;


-- task 2
-- select * from lake_raw_events;
select raw_data:event_id::varchar as EVENT_ID,
raw_data:timestamp::timestamp as EVENT_TIME,
raw_data:user_id::int as USER_ID,
raw_data:action::varchar as ACTION,
raw_data:order.total::number(12,2) as ORDER_TOTAL,
raw_data:promo_code::varchar as PROMO_CODE
from lake_raw_events
order by EVENT_ID;



-- TASK 3: Schema-on-Read Financial Analysis
-- - Calculate `NET_REVENUE` for orders where `total > 0`.
-- - Formula: `NET_REVENUE = ORDER_TOTAL - SHIPPING_COST - TAX - COALESCE(DISCOUNT_AMOUNT, 0)`

select raw_data:event_id::varchar as EVENT_ID,
raw_data:order.total::number(12,2) as ORDER_TOTAL,
raw_data:order.shipping_cost::number(12,2) as SHIPPING_COST,
raw_data:order.tax::number(12,2) as TAX,
coalesce(raw_data:discount_amount,0)::number(12,2) as DISCOUNT_AMOUNT,
(
    raw_data:order.total::number(12,2) - raw_data:order.shipping_cost::number(12,2)
    - raw_data:order.tax::number(12,2) - coalesce(raw_data:discount_amount::number(12,2),0)
) as net_revenue
from lake_raw_events
where raw_data:action::varchar='purchase'
and raw_data:order.total::number(12,2)>0
order by EVENT_ID;



-- task 4
with valid_records as (
select 
raw_data:event_id::varchar as event_id,
raw_data:action::varchar as action,
raw_data:order.total::number(12,2) as order_total
from lake_raw_events
),

kpi_data as (
select count(*) as TOTAL_EVENTS,

count_if (
action='purchase'
and order_total>0
) as TOTAL_PURCHASES,

SUM(
case 
when action='purchase'
and order_total>0
then order_total    
else 0
end 
) as TOTAL_GROSS_REVENUE
from valid_records  

)

SELECT

    TOTAL_EVENTS,

    TOTAL_PURCHASES,

    ROUND(
        TOTAL_PURCHASES * 100.0
        / NULLIF(TOTAL_EVENTS, 0),
        2
    ) AS CONVERSION_RATE_PCT,

    TOTAL_GROSS_REVENUE,

    ROUND(
        TOTAL_GROSS_REVENUE
        / NULLIF(TOTAL_PURCHASES, 0),
        2
    ) AS AVERAGE_ORDER_VALUE

FROM kpi_data;



-- TASK 5: CREATE DATA WAREHOUSE TABLE
-- Schema-on-Write

CREATE OR REPLACE TABLE dw_structured_events
(
    event_id VARCHAR NOT NULL,

    event_time TIMESTAMP_NTZ,

    user_id INTEGER,

    page VARCHAR,

    action VARCHAR,

    order_total NUMBER(12,2),

    shipping_cost NUMBER(12,2),

    tax NUMBER(12,2),

    items INTEGER,

    promo_code VARCHAR,

    discount_amount NUMBER(12,2),

    net_revenue NUMBER(12,2)
);


INSERT INTO dw_structured_events
(
    event_id,
    event_time,
    user_id,
    page,
    action,
    order_total,
    shipping_cost,
    tax,
    items,
    promo_code,
    discount_amount,
    net_revenue
)

SELECT

    raw_data:event_id::VARCHAR,

    raw_data:timestamp::TIMESTAMP_NTZ,

    raw_data:user_id::INTEGER,

    raw_data:page::VARCHAR,

    raw_data:action::VARCHAR,

    raw_data:order.total::NUMBER(12,2),

    raw_data:order.shipping_cost::NUMBER(12,2),

    raw_data:order.tax::NUMBER(12,2),

    raw_data:order.items::INTEGER,

    raw_data:promo_code::VARCHAR,

    raw_data:discount_amount::NUMBER(12,2),

    raw_data:order.total::NUMBER(12,2)
        - raw_data:order.shipping_cost::NUMBER(12,2)
        - raw_data:order.tax::NUMBER(12,2)
        - COALESCE(
            raw_data:discount_amount::NUMBER(12,2),
            0
        )

FROM lake_raw_events;



SELECT

    COUNT(*) AS STORED_RECORDS_QTY,

    SUM(NET_REVENUE) AS TOTAL_NET_REVENUE

FROM dw_structured_events;



SELECT

    quarantine_id AS QUARANTINE_ID,

    raw_record_text AS RAW_RECORD_TEXT,

    reason AS REASON

FROM quarantine_raw_events

ORDER BY quarantine_id;
