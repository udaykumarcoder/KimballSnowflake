use role accountadmin;

create database if not exists CLEANROOM_SHARED_DB;

-- select current_database();
create schema if not exists PARTNER_TELEMETRY;

use database CLEANROOM_SHARED_DB;

use schema PARTNER_TELEMETRY;

create or replace stage PARTNER_TELEMETRY_STAGE;

create or replace file format json_format
type = 'json';

create or replace table BRONZE_RETAIL_TRANSACTIONS(
payload variant,
sourcefile string,
loaded_at timestamp default current_timestamp()
);

create or replace table BRONZE_AD_EXPOSURES(
payload variant,
sourcefile string,
loaded_at timestamp default current_timestamp()
);

copy into bronze_retail_transactions(payload,sourcefile)
from (
select $1,metadata$filename
from @partner_telemetry_stage   
)
files=('retail_transactions.json')
file_format=(format_name='json_format');

copy into BRONZE_AD_EXPOSURES(payload,sourcefile)
from (
select $1,metadata$filename
from @partner_telemetry_stage   
)
files=('ad_exposures.json')
file_format=(format_name='json_format');

-- task 1
select count(*) as TOTAL_RETAIL_RECORDS from bronze_retail_transactions;


-- task 2 
CREATE OR REPLACE TABLE SILVER_ATTRIBUTION_MATCH
(
    POS_ID            STRING,
    STORE_ID          STRING,
    CAMPAIGN_NAME     STRING,
    CHANNEL           STRING,
    BASKET_VALUE      NUMBER(12,2),
    CONVERSION_HOURS  NUMBER
);
-- select * from bronze_retail_transactions;
-- select * from bronze_ad_exposures;
INSERT INTO SILVER_ATTRIBUTION_MATCH
(
    POS_ID,
    STORE_ID,
    CAMPAIGN_NAME,
    CHANNEL,
    BASKET_VALUE,
    CONVERSION_HOURS
)
select pos.payload:pos_id ,
pos.payload:store_id,
ad.payload:campaign_name,
ad.payload:channel,
pos.payload:basket_value,
datediff('hour',ad.payload:timestamp,pos.payload:timestamp)
as conversion_hours
from bronze_retail_transactions pos
join bronze_ad_exposures ad 
on pos.payload:hashed_email=ad.payload:hashed_email;

select * from SILVER_ATTRIBUTION_MATCH;


-- task 3 
create or replace secure view 
SECURE_GOLD_CAMPAIGN_ATTRIBUTION_PERFORMANCE
as 
select campaign_name,channel, count(distinct pos_id) as user_count, sum(basket_value) as tot_val,
avg(basket_value) as avg_val
from silver_attribution_match
group by campaign_name,channel
having count(distinct pos_id)>=1;

select * from secure_gold_campaign_attribution_performance;


-- task 4
create or replace share SHARE_CPG_PARTNER_ANALYTICS;

grant usage on database CLEANROOM_SHARED_DB
to share share_cpg_partner_analytics;

GRANT USAGE
ON SCHEMA CLEANROOM_SHARED_DB.PARTNER_TELEMETRY
TO SHARE SHARE_CPG_PARTNER_ANALYTICS;

grant select on view secure_gold_campaign_attribution_performance
to share share_cpg_partner_analytics;

show shares like 'share_cpg_partner_analytics';

show grants to share share_cpg_partner_analytics;

-- task 5

use role accountadmin;

create managed account CPG_READER_ACCT_01
admin_name = 'READER_ADMIN'
admin_password = 'YourStrongPassword123!'
type=reader 
comment='reader account for partner analytics ';

show managed accounts;

alter share share_cpg_partner_analytics
add accounts=BB92573;

show grants on share 
share_cpg_partner_analytics;



CREATE WAREHOUSE CPG_READER_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;


CREATE RESOURCE MONITOR CPG_READER_RESOURCE_MONITOR

    WITH
        CREDIT_QUOTA = 10
        FREQUENCY = MONTHLY
        START_TIMESTAMP = IMMEDIATELY

    TRIGGERS
        ON 75 PERCENT DO NOTIFY
        ON 90 PERCENT DO NOTIFY
        ON 100 PERCENT DO SUSPEND;

ALTER WAREHOUSE CPG_READER_WH
SET RESOURCE_MONITOR = CPG_READER_RESOURCE_MONITOR;

SELECT CURRENT_ACCOUNT();


-- now for client side  
-- run show managed account then run that account_url in incognito
-- then run that below one for account idenitifier

SELECT
    CURRENT_ORGANIZATION_NAME() AS ORGANIZATION_NAME,
    CURRENT_ACCOUNT_NAME()      AS ACCOUNT_NAME,
    CURRENT_REGION()            AS REGION;

-- client code 
-- use role accountadmin;
-- show shares like 'SHARE_CPG_PARTNER_ANALYTICS';
-- -- now inspect the share 
-- DESC SHARE ZMKOKAR.BP64443.SHARE_CPG_PARTNER_ANALYTICS;
-- SHOW VIEWS IN SCHEMA CPG_ANALYTICS.PARTNER_TELEMETRY;
-- use warehouse cpg_reader_wh;
-- SELECT *
-- FROM CPG_ANALYTICS.PARTNER_TELEMETRY.SECURE_GOLD_CAMPAIGN_ATTRIBUTION_PERFORMANCE;

-- task 6
USE ROLE ACCOUNTADMIN;

USE DATABASE CLEANROOM_SHARED_DB;

USE SCHEMA PARTNER_TELEMETRY;



-- use role accountadmin;
-- show managed accounts;

-- SHOW GRANTS TO SHARE SHARE_CPG_PARTNER_ANALYTICS;

-- GRANT SELECT ON VIEW
-- CLEANROOM_SHARED_DB.PARTNER_TELEMETRY.SECURE_GOLD_CAMPAIGN_ATTRIBUTION_PERFORMANCE
-- TO SHARE SHARE_CPG_PARTNER_ANALYTICS;



-- task 6

with pii_check as (
select 
case 
when count_if(upper(column_name)='HASHED_EMAIL')>0
then true 
else false 
end as pii_exposure_flag
from cleanroom_shared_db.information_schema.columns
where table_schema='partner_telemetry'
and table_name='SECURE_GOLD_CAMPAIGN_ATTRIBUTION_PERFORMANCE'
),
RECONCILIATION AS
(
    SELECT

        (
            SELECT SUM(BASKET_VALUE)
            FROM CLEANROOM_SHARED_DB.PARTNER_TELEMETRY
                 .SILVER_ATTRIBUTION_MATCH
        ) AS SILVER_MATCH_VAL,


        (
            SELECT SUM(TOT_VAL)
            FROM CLEANROOM_SHARED_DB.PARTNER_TELEMETRY
                 .SECURE_GOLD_CAMPAIGN_ATTRIBUTION_PERFORMANCE
        ) AS GOLD_SHARED_VAL
)

SELECT

    ROUND(SILVER_MATCH_VAL, 2)
        AS SILVER_MATCH_VAL,

    ROUND(GOLD_SHARED_VAL, 2)
        AS GOLD_SHARED_VAL,

    PII_EXPOSURE_FLAG,

    CASE
        WHEN ROUND(SILVER_MATCH_VAL, 2)
           = ROUND(GOLD_SHARED_VAL, 2)
        THEN TRUE
        ELSE FALSE
    END AS RECONCILED_FLAG
FROM RECONCILIATION
CROSS JOIN PII_CHECK;












