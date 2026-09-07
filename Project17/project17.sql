create database FINANCIAL_GOVERNANCE_DB;
use database FINANCIAL_GOVERNANCE_DB;

create schema WEALTH_CORE;
use schema WEALTH_CORE;

create or replace file format BANK_RAW_LINE_FORMAT
type='csv'
field_delimiter=none 
record_delimiter='\n'
skip_header=0
trim_space=false;

-- select current_role();

create or replace stage payload_stage;


-- SELECT
--     CURRENT_ORGANIZATION_NAME() || '-' || CURRENT_ACCOUNT_NAME()
--         AS ACCOUNT_IDENTIFIER;

-- ran in snowsql cli
-- snowsql -a ZMKOKAR-BP64443 -u UDYATENTERPRISE
-- use database FINANCIAL_GOVERNANCE_DB;
-- use schema WEALTH_CORE;
-- PUT 'file://C:/Users/methr/OneDrive/Desktop/Accelerator/notes/DataModeling/Project17/batch1.json'
--     @PAYLOAD_STAGE
--     AUTO_COMPRESS=FALSE;

-- PUT 'file://C:/Users/methr/OneDrive/Desktop/Accelerator/notes/DataModeling/Project17/batch2.json'
--     @PAYLOAD_STAGE
--     AUTO_COMPRESS=FALSE;

-- PUT 'file://C:/Users/methr/OneDrive/Desktop/Accelerator/notes/DataModeling/Project17/batch3.json'
--     @PAYLOAD_STAGE
--     AUTO_COMPRESS=FALSE;


-- -- Verify uploaded files
-- LIST @PAYLOAD_STAGE;


create or replace table STAGE_BANK_RAW_LINES(
raw_record string ,
source_file string,
loaded_at timestamp default current_timestamp()
);

copy into 
STAGE_BANK_RAW_LINES(raw_record,source_file)
from (
select $1,metadata$filename from @payload_stage
)
files=(
'batch1.json',
'batch2.json',
'batch3.json'
)
file_format=(format_name='BANK_RAW_LINE_FORMAT')
on_error='continue';

create or replace table BRONZE_BANK_PAYLOADS(
INGEST_ID number autoincrement,
PAYLOAD variant,
LOADED_AT timestamp default current_timestamp()
);

create or replace table QUARANTINE_GOVERNANCE_PAYLOADS(
quarantine_id number autoincrement,
raw_record_text string ,
source_file string ,
reason string ,
quarantined_at timestamp default current_timestamp()
);

select * from STAGE_BANK_RAW_LINES;

insert into bronze_bank_payloads(
payload
)
select try_parse_json(raw_record) from STAGE_BANK_RAW_LINES
where try_parse_json(raw_record) is not null;

select count(*) as TOTAL_BRONZE_RECORDS from  BRONZE_BANK_PAYLOADS;

insert into QUARANTINE_GOVERNANCE_PAYLOADS(raw_record_text,source_file,reason)
select raw_record,source_file,'malformed json body' from STAGE_BANK_RAW_LINES
where try_parse_json(raw_record) is null;

-- select * from quarantine_governance_payloads;
select * from bronze_bank_payloads;


create or replace table SILVER_BANK_TRANSACTIONS(
TXN_ID varchar,
CLIENT_ID number,
CLIENT_SSN varchar,
REGION varchar,
ACCOUNT_NO varchar,
AMOUNT number(12,2),
STATUS varchar,
AML_RISK_SCORE varchar
);

INSERT INTO SILVER_BANK_TRANSACTIONS
(
    TXN_ID,
    CLIENT_ID,
    CLIENT_SSN,
    REGION,
    ACCOUNT_NO,
    AMOUNT,
    STATUS,
    AML_RISK_SCORE
)
select payload:txn_id::varchar,
payload:client_id::varchar,
payload:client_ssn::varchar,
payload:region::varchar,
payload:account_no::varchar,
payload:amount::number(12,2),
payload:status::varchar,
payload:aml_risk_score::varchar
from bronze_bank_payloads;

SELECT
    COUNT(*) AS TOTAL_SILVER_RECORDS
FROM SILVER_BANK_TRANSACTIONS;

-- select current_role();
use role useradmin;
create role if not exists COMPLIANCE_OFFICER;
create role if not exists NA_ANALYST;
create role if not exists EU_ANALYST;

use role securityadmin;

grant usage on database financial_governance_db to role
compliance_officer;

grant usage on schema financial_governance_db.wealth_core to role 
compliance_officer;

grant select on table FINANCIAL_GOVERNANCE_DB.WEALTH_CORE.SILVER_BANK_TRANSACTIONS
to role compliance_officer;

use role compliance_officer;


-- USE ROLE SECURITYADMIN;
-- GRANT ROLE COMPLIANCE_OFFICER TO USER UDYATENTERPRISE;
-- use role compliance_officer;
-- select current_role();
-- select * from silver_bank_transactions;
-- select * from bronze_bank_payloads;
SHOW GRANTS TO ROLE COMPLIANCE_OFFICER;

-- SELECT CURRENT_ROLE();

-- SELECT CURRENT_SECONDARY_ROLES();
-- USE SECONDARY ROLES NONE;


-- select current_role();
-- use role compliance_officer;
-- select current_role();
select * from SILVER_BANK_TRANSACTIONS;
-- select * from bronze_bank_payloads;


use role securityadmin;
grant usage on database financial_governance_db
to role NA_ANALYST;
grant usage on schema financial_governance_db.wealth_core
to role NA_ANALYST;
grant select on table FINANCIAL_GOVERNANCE_DB.WEALTH_CORE.SILVER_BANK_TRANSACTIONS
to role NA_ANALYST;

grant usage on database financial_governance_db
to role EU_ANALYST;
grant usage on schema financial_governance_db.wealth_core
to role EU_ANALYST;
grant select on table FINANCIAL_GOVERNANCE_DB.WEALTH_CORE.SILVER_BANK_TRANSACTIONS
to role EU_ANALYST;

use role accountadmin;

select count(*) as TOTAL_SILVER_RECORDS from silver_bank_transactions;

-- task 3 
USE ROLE ACCOUNTADMIN;

-- ALTER TABLE FINANCIAL_GOVERNANCE_DB.WEALTH_CORE.SILVER_BANK_TRANSACTIONS
-- MODIFY COLUMN CLIENT_SSN
-- UNSET MASKING POLICY;
-- ALTER TABLE FINANCIAL_GOVERNANCE_DB.WEALTH_CORE.SILVER_BANK_TRANSACTIONS
-- MODIFY COLUMN account_no
-- UNSET MASKING POLICY;
create or replace masking policy MASK_SSN
as (
CLIENT_SSN string 
)
returns string 
->
case when current_role()='COMPLIANCE_OFFICER'
then client_ssn
else '****-**'|| right(client_ssn,4)
end;

alter table silver_bank_transactions
modify column client_ssn
set masking policy mask_ssn;

create or replace masking policy MASK_ACCOUNT
as (
account_no string 
)
returns string
-> case when current_role()='COMPLIANCE_OFFICER'
then account_no 
else left(account_no,4)||'****'
end;

alter table silver_bank_transactions
modify column account_no
set masking policy mask_account;

select current_role();
use role compliance_officer;
select * from silver_bank_transactions;

use role accountadmin;
GRANT ROLE NA_ANALYST TO USER UDYATENTERPRISE;
use role NA_ANALYST;

select * from silver_bank_transactions where region='NA'
order by txn_id;


-- task 4 
use role accountadmin;

create or replace row access policy RAP_REGION_POLICY
as(
region string 
)
returns boolean 
->
case 
when current_role()='COMPLIANCE_OFFICER'
THEN TRUE 
when current_role()='NA_ANALYST' AND REGION = 'NA'
THEN TRUE
WHEN CURRENT_ROLE()='EU_ANALYST' AND REGION='EU'
THEN TRUE 
ELSE FALSE 
END;

ALTER TABLE SILVER_BANK_TRANSACTIONS 
ADD ROW ACCESS POLICY RAP_REGION_POLICY
ON (REGION);

-- use role na_analyst;
-- select * from silver_bank_transactions;
use role accountadmin;
grant role eu_analyst to user udyatenterprise;
use role eu_analyst;

select * from silver_bank_transactions;


-- task 5 
use role compliance_officer;
select * from silver_bank_transactions;
use role accountadmin;
select * from bronze_bank_payloads;
create or replace secure view SECURE_GOLD_EXTERNAL_AUDIT_SUMMARY
as 
select payload:region::string as region,
sum(payload:amount::number(12,2)) as TOTAL_SETTLED_VAL,
count(*) as SETTLED_TXN_COUNT,
avg(payload:amount::number(12,2)) as AVG_SETTLED_AMOUNT
from bronze_bank_payloads
WHERE PAYLOAD:status::STRING = 'SETTLED'
group by payload:region::string;

use role useradmin;
create role if not exists AUDIT_PARTNER;
use role accountadmin;
USE ROLE SECURITYADMIN;
grant usage on database financial_governance_db
to role AUDIT_PARTNER;
grant usage on schema financial_governance_db.wealth_core
to role AUDIT_PARTNER;
GRANT SELECT
ON VIEW FINANCIAL_GOVERNANCE_DB.WEALTH_CORE.SECURE_GOLD_EXTERNAL_AUDIT_SUMMARY
TO ROLE AUDIT_PARTNER;

grant role audit_partner to user udyatenterprise;
use role audit_partner;

SELECT
    REGION,
    TOTAL_SETTLED_VAL,
    SETTLED_TXN_COUNT,
    round(AVG_SETTLED_AMOUNT,2)
FROM FINANCIAL_GOVERNANCE_DB.WEALTH_CORE.SECURE_GOLD_EXTERNAL_AUDIT_SUMMARY
ORDER BY REGION;


-- task 6 
select * from bronze_bank_payloads;

USE ROLE SECURITYADMIN;

GRANT USAGE
ON DATABASE FINANCIAL_GOVERNANCE_DB
TO ROLE COMPLIANCE_OFFICER;

GRANT USAGE
ON ALL SCHEMAS IN DATABASE FINANCIAL_GOVERNANCE_DB
TO ROLE COMPLIANCE_OFFICER;

GRANT SELECT
ON ALL TABLES IN DATABASE FINANCIAL_GOVERNANCE_DB
TO ROLE COMPLIANCE_OFFICER;

GRANT SELECT
ON ALL VIEWS IN DATABASE FINANCIAL_GOVERNANCE_DB
TO ROLE COMPLIANCE_OFFICER;

use role compliance_officer;
-- select * from SECURE_GOLD_EXTERNAL_AUDIT_SUMMARY;
select b.BRONZE_GROSS_TOTAL,
s.SILVER_GROSS_TOTAL,
g.GOLD_GROSS_TOTAL,
CASE
        WHEN B.BRONZE_GROSS_TOTAL = S.SILVER_GROSS_TOTAL
        THEN TRUE
        ELSE FALSE
    END AS RECONCILED_FLAG
from (
select sum(payload:amount) as BRONZE_GROSS_TOTAL  from bronze_bank_payloads 
) b 
cross join 
(select sum(amount) as SILVER_GROSS_TOTAL from silver_bank_transactions) s 
cross join 
(select sum(total_settled_val) as GOLD_GROSS_TOTAL from SECURE_GOLD_EXTERNAL_AUDIT_SUMMARY) g;
