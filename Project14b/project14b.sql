CREATE OR REPLACE DATABASE FINANCIAL_GATEWAY_DB;

USE DATABASE FINANCIAL_GATEWAY_DB;

CREATE OR REPLACE SCHEMA BRONZE;

USE SCHEMA BRONZE;

create file format json_format
type='json';


CREATE OR REPLACE STAGE PAYMENT_RAW_STAGE
    FILE_FORMAT = JSON_FORMAT;

CREATE OR REPLACE TABLE BRONZE_PAYMENT_PAYLOADS
(
    RAW_DATA VARIANT
);

COPY INTO BRONZE_PAYMENT_PAYLOADS
FROM @PAYMENT_RAW_STAGE
FILE_FORMAT=(FORMAT_NAME='json_format');

select count(*) as TOTAL_BRONZE_RECORDS_CT from bronze_payment_payloads;

create or replace table silver_cleaned_transactions(
txn_id varchar primary key,
merchant_id int,
merchant_name varchar,
masked_card varchar,
gross number(12,2),
processing_fee number(12,2),
net_settlement_amount number(12,2),
status varchar
);


INSERT INTO SILVER_CLEANED_TRANSACTIONS
select
    raw_data:txn_id::varchar as txn_id,
    raw_data:merchant_id::int as merchant_id,
    raw_data:merchant_name::varchar as merchant_name,
    'XXXX-XXXX-XXXX-'||right(raw_data:card_number,4) as masked_card,
    raw_data:amount::number(12,2) as gross,
    raw_data:amount::number(12,2) * (raw_data:fee_pct::number(12,2)/100) as processing_fee,
    (raw_data:amount::number(12,2)-processing_fee) as net_settlement_amount,
    raw_data:status::varchar as status
from bronze_payment_payloads;

select * from silver_cleaned_transactions;


create table gold_merchant_settlements(
merchant_id int primary key,
merchant_name string,
total_approved_gross number(12,2),
total_gateway_fees number(12,2),
total_net_payout number(12,2),
approved_count int
);

insert into gold_merchant_settlements
select merchant_id, merchant_name, sum(gross), sum(processing_fee), sum(net_settlement_amount), count(*) 
from silver_cleaned_transactions
where status='APPROVED'
group by merchant_id, merchant_name;

select*from gold_merchant_settlements order by merchant_id;

update silver_cleaned_transactions
set status='REFUNDED'
where merchant_name='TechZone' and status='APPROVED';



-- select*from silver_cleaned_transactions where merchant_name='TechZone';

select txn_id, merchant_name, gross, status from 
silver_cleaned_transactions
at(offset=>-60*5)
where merchant_name='TechZone' and status='APPROVED';

update silver_cleaned_transactions s
set status='APPROVED'
where s.txn_id in(select txn_id from silver_cleaned_transactions at(offset=>-60*100) where merchant_name='TechZone' and status='APPROVED');


select*from silver_cleaned_transactions where merchant_name='TechZone';


-- task 5

select merchant_name, sum(iff(status='APPROVED',1,0)) as approved_count, sum(iff(status='REFUNDED',1,0)) as refunded_count
from silver_cleaned_transactions
where merchant_name='TechZone'
group by merchant_name;

-- task 6

select b.bronze_gross_sum, s.silver_gross_sum, g.gold_gross_sum,
iff(b.bronze_gross_sum=s.silver_gross_sum,TRUE,FALSE) as data_match_flag
from (select sum(raw_data:amount::number(12,2)) as bronze_gross_sum from bronze_payment_payloads)b
cross join
(select sum(gross) as silver_gross_sum from silver_cleaned_transactions)s 
cross join 
(select sum(total_approved_gross) as gold_gross_sum from gold_merchant_settlements)g;

