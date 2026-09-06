CREATE OR REPLACE DATABASE LOGISTICS_LAKEHOUSE_DB;

USE DATABASE LOGISTICS_LAKEHOUSE_DB;

CREATE OR REPLACE SCHEMA FLEET_CORE;

USE SCHEMA FLEET_CORE;

create or replace file format iot_raw_text_format
type='csv'
field_delimiter=none 
record_delimiter='\n'
skip_header=0
trim_space=false ;


create or replace stage logistics_stage
file_format=iot_raw_text_format;


-- PUT 'file://C:/Users/methr/OneDrive/Desktop/Accelerator/notes/DataModeling/Project15/input.txt'
--     @LOGISTICS_STAGE
--     AUTO_COMPRESS = FALSE;

create or replace table raw_iot_landing
(
raw_record_text string
);

copy into raw_iot_landing
from @logistics_stage
file_format=(format_name='iot_raw_text_format');

create or replace table BRONZE_IOT_STREAMS(
INGEST_ID number autoincrement,
RAW_PAYLOAD variant,
RECORDED_AT timestamp default current_timestamp
);

-- select * from raw_iot_landing;
insert into BRONZE_IOT_STREAMS(RAW_PAYLOAD)
select try_parse_json(RAW_RECORD_TEXT)
from raw_iot_landing
where try_parse_json(RAW_RECORD_TEXT) is not null;

-- task 1
select count(*) as TOTAL_BRONZE_RECORDS from BRONZE_IOT_STREAMS;

-- task 2
create or replace table QUARANTINE_IOT_PAYLOADS(
QUARANTINE_ID number autoincrement,
RAW_RECORD_TEXT string,
REASON string 
);


insert into QUARANTINE_IOT_PAYLOADS(
RAW_RECORD_TEXT,
REASON
)
select RAW_RECORD_TEXT,
'MALFORMED_JSON_BODY'
from raw_iot_landing
where try_parse_json(RAW_RECORD_TEXT) is null;

select * from QUARANTINE_IOT_PAYLOADS;

CREATE OR REPLACE TABLE SILVER_CUSTOMS_CLEARANCE
(
    SHIPMENT_ID          STRING PRIMARY KEY ,
    PAYLOAD_ID           STRING,
    VEHICLE_ID            STRING,
    DESTINATION_COUNTRY   STRING,
    DECLARED_VALUE        NUMBER(12,2),
    DUTY_PCT              NUMBER(12,1),
    DUTY_AMOUNT_DUE       NUMBER(12,2),
    BORDER_CODE           STRING,
    CLEARANCE_STATUS      STRING
);


-- select * from bronze_iot_streams;

insert into silver_customs_clearance
(
    SHIPMENT_ID,
    PAYLOAD_ID,
    VEHICLE_ID,
    DESTINATION_COUNTRY,
    DECLARED_VALUE,
    DUTY_PCT,
    DUTY_AMOUNT_DUE,
    BORDER_CODE,
    CLEARANCE_STATUS
)
select 
raw_payload:data:shipment_id::string as SHIPMENT_ID,
RAW_PAYLOAD:payload_id::STRING AS PAYLOAD_ID,
raw_payload:data:vehicle_id::string as VEHICLE_ID,
raw_payload:data:destination_country::string as DEST_COUNTRY,
raw_payload:data:declared_value::number(12,2) as DECLARED_VALUE,
round(raw_payload:data:duty_pct::number(12,2),1) as DUTY_PCT,
(
(raw_payload:data:declared_value::number(12,2)
*
raw_payload:data:duty_pct::number(12,2))/100
) as DUTY_AMOUNT_DUE,
raw_payload:data:border_clearance_code::string as BORDER_CODE,
raw_payload:data:clearance_status::string as CLEARANCE_STATUS
from bronze_iot_streams
where raw_payload:payload_type='CUSTOMS';

SELECT
    SHIPMENT_ID,
    VEHICLE_ID,
    DESTINATION_COUNTRY,
    DECLARED_VALUE,
    DUTY_PCT,
    DUTY_AMOUNT_DUE,
    BORDER_CODE,
    CLEARANCE_STATUS

FROM SILVER_CUSTOMS_CLEARANCE;


-- task 4
CREATE OR REPLACE TABLE GOLD_COUNTRY_DUTY_SUMMARY
(
    DEST_COUNTRY            STRING,
    TOTAL_CLEARED_VAL       NUMBER(12,2),
    TOTAL_DUTIES_COLLECTED  NUMBER(12,2),
    AVG_DUTY_RATE_PCT       NUMBER(12,2),
    CLEARED_SHIPMENTS       NUMBER
);

insert into GOLD_COUNTRY_DUTY_SUMMARY(
    DEST_COUNTRY,
    TOTAL_CLEARED_VAL,
    TOTAL_DUTIES_COLLECTED,
    AVG_DUTY_RATE_PCT,
    CLEARED_SHIPMENTS
)
select 
DESTINATION_COUNTRY as DEST_COUNTRY,
sum(declared_value) as TOTAL_CLEARED_VAL,
sum(duty_amount_due) as TOTAL_DUTIES_COLLECTED,
sum(duty_amount_due)/sum(declared_value)*100 as AVG_DUTY_RATE_PCT,
count(CLEARANCE_STATUS) as CLEARED_SHIPMENTS
from silver_customs_clearance
where clearance_status='CLEARED'
group by DESTINATION_COUNTRY;

select * from gold_country_duty_summary order by dest_country;


-- task 5
update silver_customs_clearance
set clearance_status='REJECTED'
where DESTINATION_COUNTRY = 'CAN';

set corruption_query_id=last_query_id();

-- select * from silver_customs_clearance
-- order by shipment_id;

create or replace temporary table silver_recovery as 
select * from 
silver_customs_clearance
before (
statement=>$corruption_query_id
);

truncate table silver_customs_clearance;

insert into silver_customs_clearance
(
    SHIPMENT_ID,
    PAYLOAD_ID,
    VEHICLE_ID,
    DESTINATION_COUNTRY,
    DECLARED_VALUE,
    DUTY_PCT,
    DUTY_AMOUNT_DUE,
    BORDER_CODE,
    CLEARANCE_STATUS
)

SELECT
    SHIPMENT_ID,
    PAYLOAD_ID,
    VEHICLE_ID,
    DESTINATION_COUNTRY,
    DECLARED_VALUE,
    DUTY_PCT,
    DUTY_AMOUNT_DUE,
    BORDER_CODE,
    CLEARANCE_STATUS

FROM SILVER_RECOVERY;


select DESTINATION_COUNTRY, count_if(clearance_status='CLEARED') as CLEARED_COUNT, 
count_if(clearance_status='REJECTED') as REJECTED_COUNT from silver_customs_clearance
group by DESTINATION_COUNTRY;



-- task 6
select 
b.BRONZE_GROSS_TOTAL,
s.SILVER_GROSS_TOTAL,
g.GOLD_GROSS_TOTAL,
case 
when b.BRONZE_GROSS_TOTAL=s.SILVER_GROSS_TOTAL
and g.GOLD_GROSS_TOTAL=
(select sum(declared_value)
from silver_customs_clearance
where clearance_status='CLEARED')
then true else false 
end as RECONCILED_FLAG

from (
select sum(raw_payload:data:declared_value::number(12,2)) as BRONZE_GROSS_TOTAL 
from bronze_iot_streams
where raw_payload:payload_type::string='CUSTOMS'
) b
cross join 
(select sum(declared_value) as SILVER_GROSS_TOTAL from silver_customs_clearance) s
cross join 
(select sum(total_cleared_val) as GOLD_GROSS_TOTAL from gold_country_duty_summary) g;
