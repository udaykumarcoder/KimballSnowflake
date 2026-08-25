1.Project Name: Hospital Healthcare Analytics using Snowflake Dimensional Modeling
----------------
2. Problem Statement
-----------------------
A hospital network operates multiple hospitals and wants to build a 
Data Warehouse in Snowflake for management analytics.

The hospital currently maintains operational data about:

Patients
Doctors
Hospitals
Departments
Treatments
Patient admissions
Medical billing

Management wants to analyze two major business processes:

Business Process 1 — Patient Admissions
------------------------------------------
Every time a patient is admitted to a hospital, an admission 
transaction is recorded.

Management wants to analyze:
----------------------
Number of admissions
Length of stay
Admissions by hospital
Admissions by department
Admissions by doctor
Monthly admissions

Business Process 2 — Medical Billing
------------------------------------
Whenever a patient receives a treatment, a billing transaction is 
generated.

Management wants to analyze:

Total treatment revenue
Revenue by hospital
Revenue by department
Revenue by doctor
Revenue by treatment
Monthly revenue

The hospital wants both business processes to use common dimensions 
so that management can compare admissions and revenue using the same 
hospital, doctor, department, patient, and date dimensions.

You are a Data Warehouse developer. Your task is to implement a Kimball dimensional model in Snowflake.

3. Learning Objectives
-------------------------
After completing this project, students should be able to:

Identify business processes.
Identify business events.
Design fact tables.
Design dimension tables.
Define the grain of a fact table.
Identify additive measures.
Create surrogate keys.
Create relationships between fact and dimension tables.
Identify conformed dimensions.
Perform drill-across analysis between two fact tables.

4. Input CSV Files
--------------------
Students will be provided with 6 CSV files.

patients.csv
------------
patient_id,patient_name,gender,city,state
P101,Amit Sharma,Male,Hyderabad,Telangana
P102,Priya Reddy,Female,Warangal,Telangana
P103,Rahul Verma,Male,Vijayawada,Andhra Pradesh
P104,Neha Patel,Female,Hyderabad,Telangana
P105,Arjun Gupta,Male,Nagpur,Maharashtra
P106,Sneha Rao,Female,Bengaluru,Karnataka

doctors.csv
-----------
doctor_id,doctor_name,specialization
D201,Dr. Rao,Cardiology
D202,Dr. Mehta,Neurology
D203,Dr. Kumar,Orthopedics
D204,Dr. Sharma,General Medicine

hospitals.csv
-------------
hospital_id,hospital_name,city,state,region
H301,KMIT Hospital,Hyderabad,Telangana,South
H302,City Care Hospital,Warangal,Telangana,South
H303,Apollo Care,Vijayawada,Andhra Pradesh,South

departments.csv
---------------
department_id,department_name
DP401,Cardiology
DP402,Neurology
DP403,Orthopedics
DP404,General Medicine

treatments.csv
--------------
treatment_id,treatment_name,treatment_category
T501,ECG,Diagnostic
T502,MRI Scan,Diagnostic
T503,X-Ray,Diagnostic
T504,Consultation,Consultation
T505,Physiotherapy,Therapy
T506,Blood Test,Diagnostic

admissions.csv
--------------
admission_id,patient_id,doctor_id,hospital_id,department_id,admission_date,discharge_date
A001,P101,D201,H301,DP401,2026-01-05,2026-01-08
A002,P102,D202,H302,DP402,2026-01-10,2026-01-15
A003,P103,D203,H303,DP403,2026-01-12,2026-01-18
A004,P104,D204,H301,DP404,2026-01-20,2026-01-22
A005,P105,D201,H301,DP401,2026-02-03,2026-02-07
A006,P106,D202,H302,DP402,2026-02-08,2026-02-12
A007,P101,D201,H301,DP401,2026-02-15,2026-02-20
A008,P102,D202,H302,DP402,2026-03-02,2026-03-06
A009,P103,D203,H303,DP403,2026-03-10,2026-03-16
A010,P104,D204,H301,DP404,2026-03-18,2026-03-20

billing.csv
-------------
admission_id,patient_id,doctor_id,hospital_id,department_id,admission_date,discharge_date
A001,P101,D201,H301,DP401,2026-01-05,2026-01-08
A002,P102,D202,H302,DP402,2026-01-10,2026-01-15
A003,P103,D203,H303,DP403,2026-01-12,2026-01-18
A004,P104,D204,H301,DP404,2026-01-20,2026-01-22
A005,P105,D201,H301,DP401,2026-02-03,2026-02-07
A006,P106,D202,H302,DP402,2026-02-08,2026-02-12
A007,P101,D201,H301,DP401,2026-02-15,2026-02-20
A008,P102,D202,H302,DP402,2026-03-02,2026-03-06
A009,P103,D203,H303,DP403,2026-03-10,2026-03-16
A010,P104,D204,H301,DP404,2026-03-18,2026-03-20

Actually, there are 7 files because admissions and billing are 
separate business processes.

TASK 1 — Create Snowflake Environment
-------

TASK 2 — Create Dimension Tables
-------
Create the following dimensions:

DIM_PATIENT
DIM_DOCTOR
DIM_HOSPITAL
DIM_DEPARTMENT
DIM_TREATMENT
DIM_DATE

Use surrogate keys in the dimensions.

TASK 3 — Load Dimension Data
------------------------------
Load the CSV data into the corresponding dimension tables.
Students should use Snowflake stages and COPY INTO.

For example:
-------------
CREATE OR REPLACE FILE FORMAT CSV_FORMAT
TYPE = 'CSV'
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
SKIP_HEADER = 1;

Then create an internal stage:
--------------------------------
CREATE OR REPLACE STAGE HEALTHCARE_STAGE
FILE_FORMAT = CSV_FORMAT;

you should upload the CSV files to the stage and load them.

Expected Output:
-------------------
Patients Loaded: 6
Doctors Loaded: 4
Hospitals Loaded: 3
Departments Loaded: 4
Treatments Loaded: 6

TASK 4 — Create DIM_DATE
---------------------------
Create a date dimension covering: 2026-01-01 to 2026-03-31

The table should contain:
----------------------------
DATE_KEY
FULL_DATE
DAY
DAY_NAME
WEEK_NO
MONTH
MONTH_NAME
QUARTER
YEAR

Expected Sample Output:
------------------------
DATE_KEY   FULL_DATE    DAY   DAY_NAME   MONTH   QUARTER   YEAR
20260101   2026-01-01    1    Thursday      1       Q1      2026
20260102   2026-01-02    2    Friday        1       Q1      2026
...

TASK 5 — Identify the Business Processes
--------------------------------------------
Students must identify:
Business Process 1
Patient Admissions

Business Process 2
Medical Billing

Expected Output:
-----------------
Business Processes
-------------------
1. Patient Admissions
2. Medical Billing

TASK 6 — Create FACT_ADMISSION
-------------------------------
Structure
------------
| Column          | Type         |
| --------------- | ------------ |
| ADMISSION_KEY   | Surrogate PK |
| PATIENT_KEY     | FK           |
| DOCTOR_KEY      | FK           |
| HOSPITAL_KEY    | FK           |
| DEPARTMENT_KEY  | FK           |
| DATE_KEY        | FK           |
| ADMISSION_COUNT | Measure      |
| LENGTH_OF_STAY  | Measure      |

TASK 7 — Define FACT_ADMISSION Grain
------------------------------------
Students must explicitly define:
One record in FACT_ADMISSION represents one patient admission to one hospital, under one doctor and department, on one admission date.

Expected Output:
---------------
FACT_ADMISSION GRAIN

One record = One patient admission
to one hospital under one doctor
and department on one admission date.


TASK 8 — Create FACT_BILLING
--------------------------------
Structure
-----------
| Column           | Type         |
| ---------------- | ------------ |
| BILLING_KEY      | Surrogate PK |
| PATIENT_KEY      | FK           |
| DOCTOR_KEY       | FK           |
| HOSPITAL_KEY     | FK           |
| DEPARTMENT_KEY   | FK           |
| TREATMENT_KEY    | FK           |
| DATE_KEY         | FK           |
| QUANTITY         | Measure      |
| TREATMENT_AMOUNT | Measure      |
| DISCOUNT         | Measure      |
| NET_AMOUNT       | Measure      |

Calculate: NET_AMOUNT = TREATMENT_AMOUNT - DISCOUNT

TASK 9 — Define FACT_BILLING Grain
-----------------------------------
Students must define:One record in FACT_BILLING represents one treatment/service 
billed to one patient by one doctor at one hospital on one billing 
date.

TASK 10 — Identify Measures
-----------------------------
Students should identify:

FACT_ADMISSION
--------------
ADMISSION_COUNT
LENGTH_OF_STAY

FACT_BILLING
---------------
QUANTITY
TREATMENT_AMOUNT
DISCOUNT
NET_AMOUNT


Expected Output:
-----------------
Measures
----------------------------

FACT_ADMISSION
Admission_Count     Additive
Length_of_Stay      Additive

FACT_BILLING
Quantity            Additive
Treatment_Amount    Additive
Discount            Additive
Net_Amount          Additive


TASK 11 — Create Conformed Dimensions
--------------------------------------
Students must identify dimensions shared by both fact tables.

Expected Output:
----------------
Conformed Dimensions
--------------------
DIM_PATIENT
DIM_DOCTOR
DIM_HOSPITAL
DIM_DEPARTMENT
DIM_DATE

The treatment dimension is used only by FACT_BILLING.


TASK 12 — Build the Star Schema
--------------------------------
Students should produce the following model:
                    DIM_PATIENT
                         |
                         |
DIM_DOCTOR ------ FACT_ADMISSION ------ DIM_DATE
                         |
                    DIM_HOSPITAL
                         |
                   DIM_DEPARTMENT
and:

                    DIM_PATIENT
                         |
                         |
DIM_DOCTOR ------- FACT_BILLING ------- DIM_DATE
                         |
                    DIM_HOSPITAL
                         |
                   DIM_DEPARTMENT
                         |
                   DIM_TREATMENT

TASK 13 — Admission Analytics
-----------------------------
Generate the following report:

Exact Output:
---------------
HOSPITAL_NAME          TOTAL_ADMISSIONS
----------------------------------------
KMIT Hospital                  5
City Care Hospital             3
Apollo Care                    2


TASK 14 — Hospital Revenue Analytics
-------------------------------------
Calculate hospital-wise billing revenue.

Expected Output:
---------------
HOSPITAL_NAME          TOTAL_REVENUE
-------------------------------------
City Care Hospital          9900
KMIT Hospital               7400
Apollo Care                 5400


TASK 15 — Monthly Revenue
---------------------------
Generate monthly hospital revenue.

Expected Output
----------------
MONTH       TOTAL_REVENUE
-------------------------
2026-01          12250
2026-02           7000
2026-03           3450

TASK 16 — Doctor-wise Revenue
--------------------------------
Generate:
Doctor
Total Revenue

Expected Output:Using the supplied billing data:
----------------
DOCTOR        TOTAL_REVENUE
---------------------------
Dr. Rao           3700
Dr. Mehta         9900
Dr. Kumar         5400
Dr. Sharma        3050


TASK 17 — Drill-Across Analysis
---------------------------------
Management wants to compare:Total Admissions and Total Revenue by Hospital.

Students must combine the two fact tables through the conformed hospital dimension.

Expected Output
------------------
HOSPITAL_NAME          TOTAL_ADMISSIONS   TOTAL_REVENUE
-------------------------------------------------------
KMIT Hospital                 5               7400
City Care Hospital            3               9900
Apollo Care                   2               5400

This demonstrates the purpose of a conformed dimension: the same DIM_HOSPITAL can be used to analyze two different fact tables.

TASK 18 — Prepare Bus Matrix
-----------------------------
Students must create:

| Dimension      | FACT_ADMISSION | FACT_BILLING |
| -------------- | -------------: | -----------: |
| DIM_PATIENT    |              ✓ |            ✓ |
| DIM_DOCTOR     |              ✓ |            ✓ |
| DIM_HOSPITAL   |              ✓ |            ✓ |
| DIM_DEPARTMENT |              ✓ |            ✓ |
| DIM_DATE       |              ✓ |            ✓ |
| DIM_TREATMENT  |              — |            ✓ |

Expected Output
------------------
                 FACT_ADMISSION    FACT_BILLING

Patient                 ✓               ✓
Doctor                  ✓               ✓
Hospital                ✓               ✓
Department              ✓               ✓
Date                    ✓               ✓
Treatment               —               ✓



create warehouse hospital_wh
with 
warehouse_size='xsmall'
auto_resume=true
auto_suspend=60;

-- select current_role();

create resource monitor credits_usage
with credit_quota=20
triggers 
on 20 percent do notify 
on 25 percent do suspend_immediate;

alter warehouse hospital_wh
set resource_monitor=credits_usage;


show warehouses like 'hospital_wh';

create database hospital_db;

use database hospital_db;

create schema hospital_schema;

use schema hospital_schema;

create stage hospital_stage;

create or replace table patients(
patient_id varchar(50) primary key,
patient_name varchar(50),
gender varchar(6),
city varchar(50),
state varchar(50)
);

create or replace table doctors(
doctor_id varchar(50)primary key ,
doctor_name varchar(50),
specialization varchar(50)
);
-- show primary keys in table doctors;

create or replace table hospitals(
hospital_id varchar(50) primary key,
hospital_name varchar(50),
city varchar(50),
state varchar(50),
region varchar(50)
);
show primary keys in table hospitals;

create or replace table departments(
department_id varchar(50) primary key,
department_name varchar(50)
);

create or replace table treatments(
treatment_id varchar(50) primary key,
treatment_name varchar(50),
treatment_category varchar(50)
);

create or replace table admissions(
admission_id varchar(50) primary key,
patient_id varchar(50),
doctor_id varchar(50),
hospital_id varchar(50),
department_id varchar(50),
admission_date date,
discharge_date date ,

foreign key(patient_id) references patients(patient_id),
foreign key(doctor_id) references doctors(doctor_id),
foreign key(hospital_id) references hospitals(hospital_id),
foreign key(department_id) references departments(department_id)

);

create or replace table billings(
admission_id varchar(50) primary key,
patient_id varchar(50),
doctor_id varchar(50),
hospital_id varchar(50),
department_id varchar(50),
treatment_id varchar not null,
admission_date date,
discharge_date date ,
quantity int,
treatment_amount int,
discount int,
foreign key(patient_id) references patients(patient_id),
foreign key(doctor_id) references doctors(doctor_id),
foreign key(hospital_id) references hospitals(hospital_id),
foreign key(department_id) references departments(department_id)

);
create file format csv_format
type = 'csv'
field_delimiter=','
skip_header=1;

list @hospital_stage;

copy into patients 
from @hospital_stage/patients.csv
file_format=(format_name=csv_format);

copy into admissions 
from @hospital_stage/admissions.csv
file_format=(format_name=csv_format);

copy into billings 
from @hospital_stage/billing.csv
file_format=(format_name=csv_format);


copy into departments 
from @hospital_stage/departments.csv
file_format=(format_name=csv_format);

copy into doctors 
from @hospital_stage/doctors.csv
file_format=(format_name=csv_format);

copy into hospitals 
from @hospital_stage/hospitals.csv
file_format=(format_name=csv_format);

copy into treatments 
from @hospital_stage/treatments.csv
file_format=(format_name=csv_format);






ALTER STAGE hospital_stage
RENAME TO healthcare_stage;

list @healthcare_stage;



copy into patients 
from @healthcare_stage/patients.csv
file_format=(format_name=csv_format);

copy into admissions 
from @healthcare_stage/admissions.csv
file_format=(format_name=csv_format);

SELECT $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
FROM @healthcare_stage/billings2.csv
(FILE_FORMAT => csv_format);
copy into billings 
from @healthcare_stage/billings2.csv
file_format=(format_name=csv_format);


copy into departments 
from @healthcare_stage/departments.csv
file_format=(format_name=csv_format);

copy into doctors 
from @healthcare_stage/doctors.csv
file_format=(format_name=csv_format);

copy into hospitals 
from @healthcare_stage/hospitals.csv
file_format=(format_name=csv_format);

copy into treatments 
from @healthcare_stage/treatments.csv
file_format=(format_name=csv_format);


-- creating dimension tables 
create or replace table dim_patient(
patient_key number primary key autoincrement ,
patient_id varchar(50) ,
patient_name varchar(50),
gender varchar(6),
city varchar(50),
state varchar(50)
);

insert into dim_patient(
patient_id,patient_name,gender,city,state
)
select patient_id,patient_name,gender,city,state
from patients;

-- select count(*) from dim_patient;
-- truncate table dim_patient;

select * from dim_patient;

delete from dim_patient
where patient_key in (
select patient_key from 
(select patient_key,row_number() over(partition by patient_id order by patient_key) as rnk
from dim_patient) d
where rnk>1
);

create or replace table dim_doctor(
doctor_key number primary key autoincrement, 
doctor_id varchar(50) ,
doctor_name varchar(50),
specialization varchar(50)
);
show tables;
insert into dim_doctor(doctor_id,doctor_name,specialization)
select doctor_id,doctor_name,specialization
from DOCTORS;

select * from dim_doctor;

create or replace table dim_hospital(
hospital_key number primary key autoincrement,
hospital_id varchar(50) ,
hospital_name varchar(50),
city varchar(50),
state varchar(50),
region varchar(50)
);

insert into dim_hospital(
hospital_id,hospital_name,city,state,region
)
select hospital_id,hospital_name,city,state,region
from hospitals;


create or replace table dim_department(
department_key number primary key autoincrement,
department_id varchar(50) ,
department_name varchar(50)
);

insert into dim_department(department_id,department_name)
select department_id,department_name
from departments;

select * from dim_department;


create or replace table dim_treatment(
treatment_key number primary key autoincrement,
treatment_id varchar(50) ,
treatment_name varchar(50),
treatment_category varchar(50)
);

insert into dim_treatment(treatment_id,treatment_name,treatment_category
)select treatment_id,treatment_name,treatment_category
from treatments;


create or replace table dim_date(
date_key number primary key,
FULL_DATE date,
DAY number,
DAY_NAME varchar(50),
WEEK_NO number ,
MONTH number,
MONTH_NAME varchar(50),
QUARTER varchar(50),
YEAR number
);


insert into dim_date(
DATE_KEY,
FULL_DATE,
DAY,
DAY_NAME,
WEEK_NO,
MONTH,
MONTH_NAME,
QUARTER,
YEAR
)
select 
to_number(to_char(full_date,'YYYYMMDD')) as date_key, 
full_date,
day(full_date) as day,
dayname(full_date) as day_name,
week(full_date) as week_no,
month(full_date) as month,
monthname(full_date) as month_name,
'Q'||quarter(full_date) as quarter,
year(full_date) as year
from 
(select dateadd(day,seq4(),'2026-01-01'::date) as full_date 
from table(generator(rowcount=>90)));


select * from dim_date;


-- task 5 identifying business process

-- business process 1 - patient admission
-- businesss process 2 - medical billing




-- task 6 create fact admission table 

create or replace  table fact_admission (
admission_key number primary key autoincrement,
patient_key number references dim_patient(patient_key),
doctor_key number references dim_doctor(doctor_key),
hospital_key number references dim_hospital(hospital_key),
department_key number references dim_department(department_key),
date_key number references dim_date(date_key),
admission_count number, 
length_of_stay number 
);


-- task 7
-- fact admission grain 
-- one record = one patient admission in one hospital under one doctor and 
-- department  on one admission date 


-- task 8 
-- fact billing 
create or replace table fact_billing(
billing_key number primary key autoincrement,
patient_key number references dim_patient(patient_key),
doctor_key number references dim_doctor(doctor_key),
hospital_key number references dim_hospital(hospital_key),
department_key number references dim_department(department_key),
treatment_key number references dim_treatment(treatment_key),
date_key number references dim_date(date_key),
quantity number ,
treatment_amount number,
discount number,
net_amount number
);

-- task 9
-- fact admission grain 
-- one record = one record in fact billing represents one treatment/service billed to one patient by 
-- one doctor at one hospital on one billing date 


-- task 10
-- identifying measures

-- Fact_admission
-- admission_count additive
-- length_of_stay additive

-- Fact_billing
-- quantity additive
-- treatment_amount additive
-- discount additive
-- net_amount additive 


-- task 11 
-- identifying conformed dimensions
-- patient_key
-- doctor_key
-- hospital_key
-- date_key
-- department_key


-- task 12 build the star schema 
insert into fact_admission(
patient_key,
doctor_key ,
hospital_key ,
department_key ,
date_key,
admission_count,
length_of_stay)
select p.patient_key,d.doctor_key,h.hospital_key,
de.department_key, da.date_key, 1 as admission_count, a.discharge_date-a.admission_date as length_of_sta
from dim_patient p
join admissions a 
on p.patient_id=a.patient_id
join dim_doctor d 
on d.DOCTOR_ID=a.DOCTOR_ID
join dim_date da
on da.full_date=a.admission_date
join dim_hospital h 
on h.hospital_id=a.hospital_id
join dim_department de 
on de.department_id=a.department_id;


select * from fact_admission;


insert into fact_billing(
patient_key ,
doctor_key ,
hospital_key ,
department_key ,
treatment_key ,
date_key ,
quantity ,
treatment_amount ,
discount ,
net_amount 
)
select p.patient_key ,
doc.doctor_key ,
h.hospital_key ,
dep.department_key ,
t.treatment_key ,
da.date_key ,
b.quantity ,
b.treatment_amount ,
b.discount ,
b.treatment_amount-b.discount as net_amount 
from 
dim_patient p 
join billings b
on p.patient_id=b.patient_id
join dim_doctor doc
on doc.doctor_id=b.doctor_id
join dim_hospital h 
on h.hospital_id=b.hospital_id
join dim_department dep 
on dep.department_id=b.department_id
join dim_treatment t 
on t.TREATMENT_ID=b.treatment_id
join dim_date da 
on da.full_date=b.admission_date;

select * from fact_billing;



    -- task 13 admission analytics 
    -- select * from dim_hospital;
    -- select * from fact_admission;

    select h.hospital_name,sum(fa.admission_count) as total_admissions from
    dim_hospital h join fact_admission fa 
    on h.hospital_key=fa.hospital_key
    group by h.hospital_key,hospital_name
    order by total_admissions desc;


    -- task 14 hospital revenue analytics 
    select * from fact_billing;
    select h.hospital_name,sum(fb.net_amount) as total_revenue from 
    dim_hospital h join fact_billing fb 
    on h.hospital_key=fb.treatment_key
    group by fb.hospital_key,h.hospital_name
    order by total_revenue desc;

    -- task 15 monthly revenue 
    select to_char(da.full_date,'YYYY-MM'),sum(fb.net_amount)
    from dim_date da join fact_billing fb 
    on da.date_key=fb.date_key
    group by to_char(da.full_date,'YYYY-MM');

    -- task 16 doctorwise revenue
    select d.doctor_name,sum(fb.net_amount)
    from dim_doctor d join fact_billing fb 
    on d.doctor_key=fb.doctor_key
    group by d.doctor_key,d.doctor_name
    order by case d.doctor_name
    when 'Dr.Rao' then 4
    when 'Dr. Mehta' then 3
    when 'Dr. Sharma' then 2
    when 'Dr. Kumar' then 1
    end;


    -- task 17 drill across analysis

    -- way 1 wrong way if we join it makes multiple rows for admission 
    -- select * from fact_admission;
    -- select * from fact_billing;
    -- select * from dim_hospital;

    -- select h.hospital_name,sum(fa.admission_count),sum(fb.net_amount)
    -- from dim_hospital h 
    -- join fact_admission fa 
    -- on h.hospital_key=fa.hospital_key
    -- join fact_billing fb 
    -- on h.hospital_key=fb.hospital_key
    -- group by h.hospital_key,h.hospital_name;

    -- correct way
    -- aggregate each of them and finaljoin them
    -- cte way
    -- with cte1 as (select h.hospital_key,h.hospital_name as hospital_name,sum(fa.admission_count) as admission_count
    -- from dim_hospital h join fact_admission fa 
    -- on h.hospital_key=fa.hospital_key
    -- group by h.hospital_name,h.hospital_key),

    -- cte2 as (select h.hospital_key,h.hospital_name,sum(fb.net_amount) as revenue
    -- from dim_hospital h join fact_billing fb 
    -- on h.hospital_key=fb.hospital_key
    -- group by h.hospital_name,h.hospital_key)

    -- select c1.hospital_name,c1.admission_count,
    -- c2.revenue from cte1 c1 join cte2 c2 on c1.hospital_key=c2.hospital_key;


    -- join way 
    select d1.hospital_name,d1.admission_count from (
    select h.hospital_key,h.hospital_name as hospital_name,sum(fa.admission_count) as admission_count
    from dim_hospital h join fact_admission fa 
    on h.hospital_key=fa.hospital_key
    group by h.hospital_name,h.hospital_key) d1 
    join (
    select h.hospital_key,sum(fb.net_amount) 
    from fact_billing fb
    join dim_hospital h  
    on h.hospital_key=fb.hospital_key
    group by h.hospital_name,h.hospital_key) d2 

    on d1.hospital_key=d2.hospital_key;



    -- task 18
                     FACT_ADMISSION    FACT_BILLING

Patient                ✅              ✅
Doctor                 ✅              ✅
Hospital               ✅              ✅
Department             ✅              ✅
Date                   ✅              ✅
Treatment               —              ✅
