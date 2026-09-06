CREATE DATABASE IF NOT EXISTS HEALTHCARE_PIPELINE_DB;

USE DATABASE HEALTHCARE_PIPELINE_DB;


CREATE SCHEMA IF NOT EXISTS CLAIMS_CORE;

USE SCHEMA CLAIMS_CORE;

create or replace file format claims_raw_text_format
type='csv'
field_delimiter=none 
skip_header=0 
trim_space=False 
record_delimiter='\n';

create or replace stage claims_payload_stage
file_format=claims_raw_text_format;

-- list @claims_payload_stage;

CREATE OR REPLACE TABLE RAW_CLAIMS_FILE_STAGE
(
    RAW_RECORD_TEXT VARCHAR,
    SOURCE_FILE     VARCHAR,
    STAGED_AT       TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
);

COPY INTO RAW_CLAIMS_FILE_STAGE
(
    RAW_RECORD_TEXT,
    SOURCE_FILE
)
FROM
(
    SELECT
        $1,
        METADATA$FILENAME
    FROM @CLAIMS_PAYLOAD_STAGE/batch1
)
FILE_FORMAT = (
    FORMAT_NAME = 'CLAIMS_RAW_TEXT_FORMAT'
)
ON_ERROR = 'ABORT_STATEMENT';

-- select * from raw_claims_file_stage;

copy into raw_claims_file_stage(raw_record_text,source_file)
from (select $1,metadata$filename
from @claims_payload_stage/batch2)
file_format=(format_name=claims_raw_text_format)
on_error='abort_statement';

copy into raw_claims_file_stage(raw_record_text,source_file)
from (select $1,metadata$filename
from @claims_payload_stage/batch3)
file_format=(format_name=claims_raw_text_format)
on_error='abort_statement';

-- select * from raw_claims_file_stage;

CREATE OR REPLACE TABLE BRONZE_RAW_CLAIMS
(
    INGEST_ID INTEGER AUTOINCREMENT,
    PAYLOAD   VARIANT,
    LOADED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
);
-- always create stream just after create table and before data insertion
create or replace stream strm_bronze_claims
on table bronze_raw_claims;

insert into bronze_raw_claims(payload)
select try_parse_json(
raw_record_text
)
from raw_claims_file_stage
where try_parse_json(raw_record_text) is not null;

select count(*) as TOTAL_BRONZE_RECORDS from bronze_raw_claims;

CREATE OR REPLACE TABLE QUARANTINE_CLAIMS_PAYLOADS
(
    QUARANTINE_ID  INTEGER AUTOINCREMENT,
    RAW_RECORD_TEXT VARCHAR,
    REASON          VARCHAR
);

INSERT INTO QUARANTINE_CLAIMS_PAYLOADS
(
    RAW_RECORD_TEXT,
    REASON
)
SELECT
    RAW_RECORD_TEXT,
    'MALFORMED_JSON_BODY'
FROM RAW_CLAIMS_FILE_STAGE
WHERE TRY_PARSE_JSON(RAW_RECORD_TEXT) IS NULL;

SELECT
    QUARANTINE_ID,
    RAW_RECORD_TEXT,
    REASON
FROM QUARANTINE_CLAIMS_PAYLOADS
ORDER BY QUARANTINE_ID;


-- task 3


CREATE OR REPLACE TABLE SILVER_CLAIMS_TRANSACTIONS
(
    CLAIM_ID            VARCHAR PRIMARY KEY,
    SUBMITTED_AT        TIMESTAMP_TZ,
    PATIENT_ID          INTEGER,
    PROVIDER_ID         VARCHAR,
    DIAGNOSIS_CODE      VARCHAR,
    BILLED_AMOUNT       NUMBER(12,2),
    COPAY_AMOUNT        NUMBER(12,2),
    NET_PAYABLE_AMOUNT  NUMBER(12,2),
    STATUS              VARCHAR
);

merge into SILVER_CLAIMS_TRANSACTIONS as target 
using (
select
         payload:claim_id::string as claim_id,
         payload:submitted_at::timestamp as submitted_at,
         payload:patient_id::int as patient_id,
         payload:provider_id::string as provider_id,
         payload:diagnosis_code::string as diagnosis_code,
         payload:billed_amount::number(12,2) as billed_amount,
         payload:copay_amount::number(12,2) as copay_amount,
         (payload:billed_amount::number(12,2) - payload:copay_amount::number(12,2)) as net_payable_amount,
         payload:status::string as status
    from strm_bronze_claims
    qualify row_number() over(
         partition by payload:claim_id::string
          ORDER BY INGEST_ID DESC
    ) = 1
) src 
on target.claim_id=src.claim_id
WHEN MATCHED THEN UPDATE SET

    TARGET.SUBMITTED_AT =
        src.SUBMITTED_AT,

    TARGET.PATIENT_ID =
        src.PATIENT_ID,

    TARGET.PROVIDER_ID =
        src.PROVIDER_ID,

    TARGET.DIAGNOSIS_CODE =
        src.DIAGNOSIS_CODE,

    TARGET.BILLED_AMOUNT =
        src.BILLED_AMOUNT,

    TARGET.COPAY_AMOUNT =
        src.COPAY_AMOUNT,

    TARGET.NET_PAYABLE_AMOUNT =
        src.NET_PAYABLE_AMOUNT,

    TARGET.STATUS =
        src.STATUS
WHEN NOT MATCHED THEN INSERT
(
    CLAIM_ID,
    SUBMITTED_AT,
    PATIENT_ID,
    PROVIDER_ID,
    DIAGNOSIS_CODE,
    BILLED_AMOUNT,
    COPAY_AMOUNT,
    NET_PAYABLE_AMOUNT,
    STATUS
)
VALUES
(
    src.CLAIM_ID,
    src.SUBMITTED_AT,
    src.PATIENT_ID,
    src.PROVIDER_ID,
    src.DIAGNOSIS_CODE,
    src.BILLED_AMOUNT,
    src.COPAY_AMOUNT,
    src.NET_PAYABLE_AMOUNT,
    src.STATUS
);

SELECT
    CLAIM_ID,
    PATIENT_ID,
    PROVIDER_ID,
    DIAGNOSIS_CODE,
    BILLED_AMOUNT,
    COPAY_AMOUNT,
    NET_PAYABLE_AMOUNT,
    STATUS
FROM SILVER_CLAIMS_TRANSACTIONS
ORDER BY CLAIM_ID;

create or replace dynamic table DT_PROVIDER_FINANCIAL_SUMMARY
    target_lag='1 minute'
    warehouse=compute_wh
    refresh_mode=incremental
    as 
    SELECT

    PROVIDER_ID,

    SUM(BILLED_AMOUNT)
        AS TOTAL_BILLED_AMOUNT,

    SUM(COPAY_AMOUNT)
        AS TOTAL_COPAY_COLLECT,

    SUM(NET_PAYABLE_AMOUNT)
        AS TOTAL_NET_PAYABLE,

    COUNT(*)
        AS APPROVED_CLAIMS

FROM SILVER_CLAIMS_TRANSACTIONS
WHERE STATUS = 'APPROVED'
GROUP BY PROVIDER_ID;

SHOW DYNAMIC TABLES LIKE 'DT_PROVIDER_FINANCIAL_SUMMARY'
IN SCHEMA HEALTHCARE_PIPELINE_DB.CLAIMS_CORE;

-- task 5
-- SELECT
--     NAME AS DYNAMIC_TABLE_NAME,
--     REFRESH_ACTION,
--     REFRESH_TRIGGER,
--     STATE AS REFRESH_STATUS,
--     REFRESH_START_TIME,
--     REFRESH_END_TIME
-- FROM TABLE
-- (
--     INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY
--     (
--         NAME_PREFIX =>
--         'HEALTHCARE_PIPELINE_DB.CLAIMS_CORE.DT_PROVIDER_FINANCIAL_SUMMARY'
--     )
-- )
-- ORDER BY REFRESH_START_TIME DESC;


SELECT
    NAME AS DYNAMIC_TABLE_NAME,
    'REFRESH' AS REFRESH_ACTION,
    REFRESH_ACTION AS REFRESH_MODE,
    STATE AS QUALIFIED_STATUS
FROM TABLE
(
    INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY
    (
        NAME_PREFIX =>
        'HEALTHCARE_PIPELINE_DB.CLAIMS_CORE.DT_PROVIDER_FINANCIAL_SUMMARY'
    )
)
WHERE STATE = 'SUCCEEDED'
ORDER BY REFRESH_START_TIME DESC
LIMIT 1;



select *
from table(information_schema.dynamic_table_graph_history())
where name='DT_PROVIDER_FINANCIAL_SUMMARY';

select b.bronze_gross_total, s.silver_gross_total, d.gold_gross_total, case when b.bronze_gross_total >= s.silver_gross_total and s.silver_gross_total >= d.gold_gross_total then 'TRUE' else 'FALSE' end as reconciled_flag
from 
(select sum(payload:billed_amount::number(12,2)) as bronze_gross_total from bronze_raw_claims) b
cross join 
(select sum(billed_amount) as silver_gross_total from silver_claims_transactions) s
cross join
(select sum(total_billed_amount) as gold_gross_total from dt_provider_financial_summary)d;
