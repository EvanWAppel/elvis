============================== 7bd66076-1874-4980-a7d7-87f52da749ff ==============================
-- created_at: 2026-03-19T23:53:04.827073087+00:00
-- finished_at: 2026-03-19T23:53:04.970732311+00:00
-- elapsed: 143ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c32479-0308-2467-0023-c55300017f46
-- desc: Get table schema
describe table "PC_DBT_DB"."RAW"."SNHD_INSPECTIONS";
-- created_at: 2026-03-19T23:53:06.201662123+00:00
-- finished_at: 2026-03-19T23:53:06.365199318+00:00
-- elapsed: 163ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c32479-0308-276f-0023-c5530002018e
-- desc: execute adapter call
show terse schemas in database PC_DBT_DB
    limit 10000
/* {"app": "dbt", "connection_name": "", "dbt_version": "2.0.0", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-19T23:53:06.365958787+00:00
-- finished_at: 2026-03-19T23:53:06.643237360+00:00
-- elapsed: 277ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c32479-0308-2621-0023-c55300019cda
-- desc: execute adapter call
create schema if not exists PC_DBT_DB.dbt_EAppel
/* {"app": "dbt", "connection_name": "", "dbt_version": "2.0.0", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-19T23:53:07.112336959+00:00
-- finished_at: 2026-03-19T23:53:07.306521182+00:00
-- elapsed: 194ms
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.stg_snhd_inspections
-- query_id: 01c32479-0308-2621-0023-c55300019cde
-- desc: get_relation > list_relations call
SHOW OBJECTS IN SCHEMA "PC_DBT_DB"."DBT_EAPPEL" LIMIT 10000;
-- created_at: 2026-03-19T23:53:07.308682689+00:00
-- finished_at: 2026-03-19T23:53:07.886330690+00:00
-- elapsed: 577ms
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.stg_snhd_inspections
-- query_id: 01c32479-0308-24a8-0023-c55300018d2a
-- desc: execute adapter call
create or replace   view PC_DBT_DB.dbt_EAppel.stg_snhd_inspections
  
  
  
  
  as (
    with source as (
    select * from PC_DBT_DB.RAW.snhd_inspections
),

renamed as (
    select
        serial_number,
        permit_number,
        restaurant_name,
        location_name,
        category_name,
        address,
        city,
        state,
        zip,
        current_demerits::integer    as current_demerits,
        current_grade,
        try_to_date(date_current)    as date_current,
        try_to_date(inspection_date) as inspection_date,
        inspection_time,
        employee_id,
        inspection_type,
        inspection_demerits::integer as inspection_demerits,
        inspection_grade,
        permit_status,
        inspection_result,
        violations::integer          as violations,
        try_to_timestamp(record_updated) as record_updated,
        objectid
    from source
)

select * from renamed
  )
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.elvis.stg_snhd_inspections", "profile_name": "user", "target_name": "default"} */;

============================== 6634ad57-4cd8-4d3c-8af1-bfa388772660 ==============================
-- created_at: 2026-03-20T16:25:59.296054703+00:00
-- finished_at: 2026-03-20T16:25:59.636003114+00:00
-- elapsed: 339ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c32859-0308-2467-0023-c55300026e3e
-- desc: Get table schema
describe table "PC_DBT_DB"."DBT_EAPPEL"."STG_SNHD_INSPECTIONS";
-- created_at: 2026-03-20T16:26:00.783033003+00:00
-- finished_at: 2026-03-20T16:26:01.017516095+00:00
-- elapsed: 234ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c3285a-0308-2a04-0023-c5530004413e
-- desc: execute adapter call
show terse schemas in database PC_DBT_DB
    limit 10000
/* {"app": "dbt", "connection_name": "", "dbt_version": "2.0.0", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:26:01.660481613+00:00
-- finished_at: 2026-03-20T16:26:01.963586307+00:00
-- elapsed: 303ms
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.mart_top_violations
-- query_id: 01c3285a-0308-2621-0023-c5530002cea6
-- desc: get_relation > list_relations call
SHOW OBJECTS IN SCHEMA "PC_DBT_DB"."DBT_EAPPEL" LIMIT 10000;
-- created_at: 2026-03-20T16:26:01.965873642+00:00
-- finished_at: 2026-03-20T16:26:04.364709121+00:00
-- elapsed: 2.4s
-- outcome: error
-- error vendor code: 100038
-- error message: Internal: [Snowflake] 100038 (22018): Numeric value '202|2955' is not recognized
-- dialect: snowflake
-- node_id: model.elvis.mart_top_violations
-- query_id: not available
-- desc: execute adapter call
create or replace transient  table PC_DBT_DB.dbt_EAppel.mart_top_violations
    
    
    
    as (

with inspections as (
    select * from PC_DBT_DB.dbt_EAppel.stg_snhd_inspections
    where violations is not null
      and violations > 0
      and inspection_date is not null
)

select
    category_name,
    inspection_type,
    inspection_grade,
    count(*)           as inspection_count,
    sum(violations)    as total_violations,
    avg(violations)    as avg_violations_per_inspection,
    max(violations)    as max_violations
from inspections
group by 1, 2, 3
order by total_violations desc
    )

/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.elvis.mart_top_violations", "profile_name": "user", "target_name": "default"} */;

============================== 2d627de1-77d8-4010-8575-bf214609d1ee ==============================
-- created_at: 2026-03-20T16:35:05.642819309+00:00
-- finished_at: 2026-03-20T16:35:05.861101206+00:00
-- elapsed: 218ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c32863-0308-24a8-0023-c5530002dc76
-- desc: Get table schema
describe table "PC_DBT_DB"."DBT_EAPPEL"."STG_SNHD_INSPECTIONS";
-- created_at: 2026-03-20T16:35:06.958689842+00:00
-- finished_at: 2026-03-20T16:35:07.191328818+00:00
-- elapsed: 232ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c32863-0308-28d8-0023-c5530003e342
-- desc: execute adapter call
show terse schemas in database PC_DBT_DB
    limit 10000
/* {"app": "dbt", "connection_name": "", "dbt_version": "2.0.0", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:35:07.793370733+00:00
-- finished_at: 2026-03-20T16:35:07.973192462+00:00
-- elapsed: 179ms
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.mart_inspections_over_time
-- query_id: 01c32863-0308-24a8-0023-c5530002dc7a
-- desc: get_relation > list_relations call
SHOW OBJECTS IN SCHEMA "PC_DBT_DB"."DBT_EAPPEL" LIMIT 10000;
-- created_at: 2026-03-20T16:35:07.908657344+00:00
-- finished_at: 2026-03-20T16:35:08.248919600+00:00
-- elapsed: 340ms
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.mart_top_violations
-- query_id: 01c32863-0308-2467-0023-c55300026e4e
-- desc: get_relation > list_relations call
SHOW OBJECTS IN SCHEMA "PC_DBT_DB"."DBT_EAPPEL" LIMIT 10000;
-- created_at: 2026-03-20T16:35:07.921766989+00:00
-- finished_at: 2026-03-20T16:35:08.272273357+00:00
-- elapsed: 350ms
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.mart_restaurant_grades
-- query_id: 01c32863-0308-29ec-0023-c55300045182
-- desc: get_relation > list_relations call
SHOW OBJECTS IN SCHEMA "PC_DBT_DB"."DBT_EAPPEL" LIMIT 10000;
-- created_at: 2026-03-20T16:35:08.251088027+00:00
-- finished_at: 2026-03-20T16:35:10.488487981+00:00
-- elapsed: 2.2s
-- outcome: error
-- error vendor code: 100038
-- error message: Internal: [Snowflake] 100038 (22018): Numeric value '2910|2912|2930|2956' is not recognized
-- dialect: snowflake
-- node_id: model.elvis.mart_top_violations
-- query_id: not available
-- desc: execute adapter call
create or replace transient  table PC_DBT_DB.dbt_EAppel.mart_top_violations
    
    
    
    as (

with inspections as (
    select * from PC_DBT_DB.dbt_EAppel.stg_snhd_inspections
    where try_to_number(violations::varchar) is not null
      and violations > 0
      and inspection_date is not null
)

select
    category_name,
    inspection_type,
    inspection_grade,
    count(*)           as inspection_count,
    sum(violations)    as total_violations,
    avg(violations)    as avg_violations_per_inspection,
    max(violations)    as max_violations
from inspections
group by 1, 2, 3
order by total_violations desc
    )

/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.elvis.mart_top_violations", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:35:07.975556833+00:00
-- finished_at: 2026-03-20T16:35:10.613001059+00:00
-- elapsed: 2.6s
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.mart_inspections_over_time
-- query_id: 01c32863-0308-2a04-0023-c5530004415e
-- desc: execute adapter call
create or replace transient  table PC_DBT_DB.dbt_EAppel.mart_inspections_over_time
    
    
    
    as (

with inspections as (
    select * from PC_DBT_DB.dbt_EAppel.stg_snhd_inspections
    where inspection_date is not null
)

select
    date_trunc('month', inspection_date)     as inspection_month,
    inspection_type,
    count(*)                                 as inspection_count,
    avg(inspection_demerits)                 as avg_demerits,
    sum(case when inspection_result = 'Compliant' then 1 else 0 end)  as compliant_count,
    sum(case when inspection_result != 'Compliant' then 1 else 0 end) as non_compliant_count,
    round(
        sum(case when inspection_result = 'Compliant' then 1 else 0 end) / count(*) * 100, 1
    )                                        as compliance_rate_pct
from inspections
group by 1, 2
order by 1, 2
    )

/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.elvis.mart_inspections_over_time", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:35:08.274386517+00:00
-- finished_at: 2026-03-20T16:35:10.706958850+00:00
-- elapsed: 2.4s
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.mart_restaurant_grades
-- query_id: 01c32863-0308-2a04-0023-c55300044162
-- desc: execute adapter call
create or replace transient  table PC_DBT_DB.dbt_EAppel.mart_restaurant_grades
    
    
    
    as (

with inspections as (
    select * from PC_DBT_DB.dbt_EAppel.stg_snhd_inspections
    where inspection_date is not null
),

latest_per_restaurant as (
    select
        permit_number,
        restaurant_name,
        location_name,
        category_name,
        address,
        city,
        state,
        zip,
        current_grade,
        current_demerits,
        date_current,
        permit_status,
        row_number() over (
            partition by permit_number
            order by inspection_date desc
        ) as rn
    from inspections
),

restaurant_history as (
    select
        permit_number,
        count(*)                          as total_inspections,
        avg(inspection_demerits)          as avg_demerits,
        min(inspection_date)              as first_inspection,
        max(inspection_date)              as last_inspection,
        sum(case when inspection_result = 'Compliant' then 1 else 0 end)  as compliant_count,
        sum(case when inspection_result != 'Compliant' then 1 else 0 end) as non_compliant_count
    from inspections
    group by permit_number
)

select
    l.permit_number,
    l.restaurant_name,
    l.location_name,
    l.category_name,
    l.address,
    l.city,
    l.state,
    l.zip,
    l.current_grade,
    l.current_demerits,
    l.date_current,
    l.permit_status,
    h.total_inspections,
    round(h.avg_demerits, 1)   as avg_demerits,
    h.first_inspection,
    h.last_inspection,
    h.compliant_count,
    h.non_compliant_count,
    round(
        h.compliant_count / nullif(h.total_inspections, 0) * 100, 1
    )                          as compliance_rate_pct
from latest_per_restaurant l
join restaurant_history h using (permit_number)
where l.rn = 1
    )

/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.elvis.mart_restaurant_grades", "profile_name": "user", "target_name": "default"} */;

============================== 376fb036-0bd4-4551-8508-b3702ff829cf ==============================
-- created_at: 2026-03-20T16:41:20.618880723+00:00
-- finished_at: 2026-03-20T16:41:20.949205775+00:00
-- elapsed: 330ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c32869-0308-2621-0023-c5530002ceca
-- desc: Get table schema
describe table "PC_DBT_DB"."RAW"."SNHD_INSPECTIONS";
-- created_at: 2026-03-20T16:41:21.591139138+00:00
-- finished_at: 2026-03-20T16:41:21.776226202+00:00
-- elapsed: 185ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c32869-0308-2a04-0023-c55300044182
-- desc: execute adapter call
show terse schemas in database PC_DBT_DB
    limit 10000
/* {"app": "dbt", "connection_name": "", "dbt_version": "2.0.0", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:41:22.330416533+00:00
-- finished_at: 2026-03-20T16:41:22.711934006+00:00
-- elapsed: 381ms
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.stg_snhd_inspections
-- query_id: 01c32869-0308-2621-0023-c5530002cece
-- desc: get_relation > list_relations call
SHOW OBJECTS IN SCHEMA "PC_DBT_DB"."DBT_EAPPEL" LIMIT 10000;
-- created_at: 2026-03-20T16:41:22.714333149+00:00
-- finished_at: 2026-03-20T16:41:23.190184197+00:00
-- elapsed: 475ms
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.stg_snhd_inspections
-- query_id: 01c32869-0308-2a04-0023-c55300044186
-- desc: execute adapter call
create or replace   view PC_DBT_DB.dbt_EAppel.stg_snhd_inspections
  
  
  
  
  as (
    with source as (
    select * from PC_DBT_DB.RAW.snhd_inspections
),

renamed as (
    select
        serial_number,
        permit_number,
        restaurant_name,
        location_name,
        category_name,
        address,
        city,
        state,
        zip,
        current_demerits::integer    as current_demerits,
        current_grade,
        try_to_date(date_current)    as date_current,
        try_to_date(inspection_date) as inspection_date,
        inspection_time,
        employee_id,
        inspection_type,
        inspection_demerits::integer as inspection_demerits,
        inspection_grade,
        permit_status,
        inspection_result,
        violations                   as violation_codes,
        case
            when violations is null or violations = '' then 0
            else array_size(split(violations, '|'))
        end                          as violation_count,
        try_to_timestamp(record_updated) as record_updated,
        objectid
    from source
)

select * from renamed
  )
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.elvis.stg_snhd_inspections", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:41:23.658003738+00:00
-- finished_at: 2026-03-20T16:41:26.288824814+00:00
-- elapsed: 2.6s
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.mart_top_violations
-- query_id: 01c32869-0308-28d8-0023-c5530003e352
-- desc: execute adapter call
create or replace transient  table PC_DBT_DB.dbt_EAppel.mart_top_violations
    
    
    
    as (

with inspections as (
    select * from PC_DBT_DB.dbt_EAppel.stg_snhd_inspections
    where violation_codes is not null
      and violation_codes != ''
      and inspection_date is not null
),

flattened as (
    select
        i.category_name,
        i.inspection_type,
        i.inspection_grade,
        i.inspection_date,
        trim(v.value::varchar) as violation_code
    from inspections i,
    lateral flatten(input => split(i.violation_codes, '|')) v
)

select
    violation_code,
    category_name,
    inspection_type,
    count(*) as occurrence_count
from flattened
where violation_code != ''
group by 1, 2, 3
order by occurrence_count desc
    )

/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.elvis.mart_top_violations", "profile_name": "user", "target_name": "default"} */;

============================== 40b20e4b-4c61-4b9f-b539-952985b4c4ec ==============================

============================== 8095eb5a-bd7d-41ef-8c9f-ff2ad12062d8 ==============================
-- created_at: 2026-03-20T16:44:36.492661452+00:00
-- finished_at: 2026-03-20T16:44:36.751108865+00:00
-- elapsed: 258ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c3286c-0308-24a8-0023-c5530002dc96
-- desc: Get table schema
describe table "PC_DBT_DB"."DBT_EAPPEL"."MART_INSPECTIONS_OVER_TIME";
-- created_at: 2026-03-20T16:44:36.763068916+00:00
-- finished_at: 2026-03-20T16:44:36.914022307+00:00
-- elapsed: 150ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c3286c-0308-2467-0023-c55300026e62
-- desc: Get table schema
describe table "PC_DBT_DB"."DBT_EAPPEL"."MART_RESTAURANT_GRADES";
-- created_at: 2026-03-20T16:44:36.893731975+00:00
-- finished_at: 2026-03-20T16:44:37.103757863+00:00
-- elapsed: 210ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c3286c-0308-28d7-0023-c5530002fbaa
-- desc: Get table schema
describe table "PC_DBT_DB"."DBT_EAPPEL"."MART_TOP_VIOLATIONS";
-- created_at: 2026-03-20T16:44:36.914575294+00:00
-- finished_at: 2026-03-20T16:44:37.137047361+00:00
-- elapsed: 222ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c3286c-0308-29ec-0023-c5530004518e
-- desc: Get table schema
describe table "PC_DBT_DB"."DBT_EAPPEL"."STG_SNHD_INSPECTIONS";
-- created_at: 2026-03-20T16:44:38.321665137+00:00
-- finished_at: 2026-03-20T16:44:39.074096530+00:00
-- elapsed: 752ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.elvis.not_null_stg_snhd_inspections_permit_number.9a7b62a1f1
-- query_id: 01c3286c-0308-28d7-0023-c5530002fbae
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select permit_number
from PC_DBT_DB.dbt_EAppel.stg_snhd_inspections
where permit_number is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.elvis.not_null_stg_snhd_inspections_permit_number.9a7b62a1f1", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:44:38.245691473+00:00
-- finished_at: 2026-03-20T16:44:39.087145549+00:00
-- elapsed: 841ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.elvis.not_null_mart_inspections_over_time_inspection_count.52be5185c0
-- query_id: 01c3286c-0308-2621-0023-c5530002cee6
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select inspection_count
from PC_DBT_DB.dbt_EAppel.mart_inspections_over_time
where inspection_count is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.elvis.not_null_mart_inspections_over_time_inspection_count.52be5185c0", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:44:38.289690358+00:00
-- finished_at: 2026-03-20T16:44:39.091201927+00:00
-- elapsed: 801ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.elvis.not_null_mart_top_violations_violation_code.271f25ddf4
-- query_id: 01c3286c-0308-29ec-0023-c55300045196
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select violation_code
from PC_DBT_DB.dbt_EAppel.mart_top_violations
where violation_code is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.elvis.not_null_mart_top_violations_violation_code.271f25ddf4", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:44:38.249794447+00:00
-- finished_at: 2026-03-20T16:44:39.094344236+00:00
-- elapsed: 844ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.elvis.not_null_stg_snhd_inspections_serial_number.0350d88527
-- query_id: 01c3286c-0308-2467-0023-c55300026e6a
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select serial_number
from PC_DBT_DB.dbt_EAppel.stg_snhd_inspections
where serial_number is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.elvis.not_null_stg_snhd_inspections_serial_number.0350d88527", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:44:38.327414115+00:00
-- finished_at: 2026-03-20T16:44:39.095842730+00:00
-- elapsed: 768ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.elvis.not_null_mart_inspections_over_time_inspection_month.0c38970b66
-- query_id: 01c3286c-0308-2467-0023-c55300026e6e
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select inspection_month
from PC_DBT_DB.dbt_EAppel.mart_inspections_over_time
where inspection_month is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.elvis.not_null_mart_inspections_over_time_inspection_month.0c38970b66", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:44:38.245355511+00:00
-- finished_at: 2026-03-20T16:44:39.096598768+00:00
-- elapsed: 851ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.elvis.not_null_mart_restaurant_grades_permit_number.1918265f9e
-- query_id: 01c3286c-0308-29ec-0023-c55300045192
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select permit_number
from PC_DBT_DB.dbt_EAppel.mart_restaurant_grades
where permit_number is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.elvis.not_null_mart_restaurant_grades_permit_number.1918265f9e", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:44:38.238698292+00:00
-- finished_at: 2026-03-20T16:44:39.236135364+00:00
-- elapsed: 997ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.elvis.accepted_values_stg_snhd_inspe_64bf69037ae18d0af52096c19dc13312.588921fd54
-- query_id: 01c3286c-0308-2467-0023-c55300026e66
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        inspection_grade as value_field,
        count(*) as n_records

    from PC_DBT_DB.dbt_EAppel.stg_snhd_inspections
    group by inspection_grade

)

select *
from all_values
where value_field not in (
    'A','B','C',''
)



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.elvis.accepted_values_stg_snhd_inspe_64bf69037ae18d0af52096c19dc13312.588921fd54", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:44:38.291387240+00:00
-- finished_at: 2026-03-20T16:44:39.276773453+00:00
-- elapsed: 985ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.elvis.accepted_values_stg_snhd_inspe_0cf7dfb672507501f72f77f225ffe2e6.a0f232fb64
-- query_id: 01c3286c-0308-29ec-0023-c5530004519a
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        inspection_result as value_field,
        count(*) as n_records

    from PC_DBT_DB.dbt_EAppel.stg_snhd_inspections
    group by inspection_result

)

select *
from all_values
where value_field not in (
    'Compliant','Non-Compliant','Corrected On-Site','Out of Business','"B" Downgrade','"C" Downgrade','Closed','Voluntary Closure'
)



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.elvis.accepted_values_stg_snhd_inspe_0cf7dfb672507501f72f77f225ffe2e6.a0f232fb64", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:44:38.338128691+00:00
-- finished_at: 2026-03-20T16:44:39.279485643+00:00
-- elapsed: 941ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.elvis.not_null_mart_restaurant_grades_total_inspections.13bb432ea6
-- query_id: 01c3286c-0308-238f-0023-c55300047102
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select total_inspections
from PC_DBT_DB.dbt_EAppel.mart_restaurant_grades
where total_inspections is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.elvis.not_null_mart_restaurant_grades_total_inspections.13bb432ea6", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:44:38.289651106+00:00
-- finished_at: 2026-03-20T16:44:39.306515904+00:00
-- elapsed: 1.0s
-- outcome: success
-- dialect: snowflake
-- node_id: test.elvis.not_null_mart_top_violations_occurrence_count.196cf3466e
-- query_id: 01c3286c-0308-26c9-0023-c5530003f296
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select occurrence_count
from PC_DBT_DB.dbt_EAppel.mart_top_violations
where occurrence_count is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.elvis.not_null_mart_top_violations_occurrence_count.196cf3466e", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:44:38.285247440+00:00
-- finished_at: 2026-03-20T16:44:39.602043566+00:00
-- elapsed: 1.3s
-- outcome: success
-- dialect: snowflake
-- node_id: test.elvis.not_null_stg_snhd_inspections_violation_count.1f98e40c2e
-- query_id: 01c3286c-0308-26c9-0023-c5530003f29a
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select violation_count
from PC_DBT_DB.dbt_EAppel.stg_snhd_inspections
where violation_count is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.elvis.not_null_stg_snhd_inspections_violation_count.1f98e40c2e", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:44:38.316986007+00:00
-- finished_at: 2026-03-20T16:44:39.610796276+00:00
-- elapsed: 1.3s
-- outcome: success
-- dialect: snowflake
-- node_id: test.elvis.unique_mart_restaurant_grades_permit_number.8e384ad830
-- query_id: 01c3286c-0308-2a04-0023-c5530004418e
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    permit_number as unique_field,
    count(*) as n_records

from PC_DBT_DB.dbt_EAppel.mart_restaurant_grades
where permit_number is not null
group by permit_number
having count(*) > 1



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.elvis.unique_mart_restaurant_grades_permit_number.8e384ad830", "profile_name": "user", "target_name": "default"} */;

============================== a1e4221b-3d7c-4cb6-b58e-84cdf6b0b24f ==============================
-- created_at: 2026-03-20T16:46:06.282364829+00:00
-- finished_at: 2026-03-20T16:46:06.431770919+00:00
-- elapsed: 149ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c3286e-0308-2467-0023-c55300026e7a
-- desc: Get table schema
describe table "PC_DBT_DB"."DBT_EAPPEL"."STG_SNHD_INSPECTIONS";
-- created_at: 2026-03-20T16:46:07.334874867+00:00
-- finished_at: 2026-03-20T16:46:08.438023093+00:00
-- elapsed: 1.1s
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: not available
-- desc: dbt run query
select * from (select distinct inspection_result from PC_DBT_DB.dbt_EAppel.stg_snhd_inspections order by 1
) limit 10;

============================== ad6e11f3-e420-40e7-ac3f-f204ba1a4d9c ==============================
-- created_at: 2026-03-20T16:47:00.318829557+00:00
-- finished_at: 2026-03-20T16:47:00.478211243+00:00
-- elapsed: 159ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c3286f-0308-29eb-0023-c5530004128a
-- desc: Get table schema
describe table "PC_DBT_DB"."DBT_EAPPEL"."STG_SNHD_INSPECTIONS";
-- created_at: 2026-03-20T16:47:01.457736730+00:00
-- finished_at: 2026-03-20T16:47:01.948633661+00:00
-- elapsed: 490ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: not available
-- desc: dbt run query
select * from (select distinct inspection_result from PC_DBT_DB.dbt_EAppel.stg_snhd_inspections order by 1
) limit 10;

============================== c6f20e93-2481-4a6b-9f36-bd754d03f1f6 ==============================
-- created_at: 2026-03-20T16:47:16.939598097+00:00
-- finished_at: 2026-03-20T16:47:17.124963176+00:00
-- elapsed: 185ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c3286f-0308-29ec-0023-c553000451a2
-- desc: Get table schema
describe table "PC_DBT_DB"."DBT_EAPPEL"."STG_SNHD_INSPECTIONS";
-- created_at: 2026-03-20T16:47:18.483022519+00:00
-- finished_at: 2026-03-20T16:47:19.621882503+00:00
-- elapsed: 1.1s
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: not available
-- desc: dbt run query
select * from (select distinct inspection_grade from PC_DBT_DB.dbt_EAppel.stg_snhd_inspections order by 1
) limit 10;

============================== ee1c4603-fed4-4b0b-82ce-a3bd0db2b0fd ==============================
-- created_at: 2026-03-20T16:49:07.925064581+00:00
-- finished_at: 2026-03-20T16:49:08.077481701+00:00
-- elapsed: 152ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c32871-0308-28d8-0023-c5530003e37e
-- desc: Get table schema
describe table "PC_DBT_DB"."DBT_EAPPEL"."MART_RESTAURANT_GRADES";
-- created_at: 2026-03-20T16:49:07.918730614+00:00
-- finished_at: 2026-03-20T16:49:08.079012461+00:00
-- elapsed: 160ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c32871-0308-29ec-0023-c553000451aa
-- desc: Get table schema
describe table "PC_DBT_DB"."DBT_EAPPEL"."MART_INSPECTIONS_OVER_TIME";
-- created_at: 2026-03-20T16:49:08.086296231+00:00
-- finished_at: 2026-03-20T16:49:08.264861492+00:00
-- elapsed: 178ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c32871-0308-29eb-0023-c55300041292
-- desc: Get table schema
describe table "PC_DBT_DB"."DBT_EAPPEL"."MART_TOP_VIOLATIONS";
-- created_at: 2026-03-20T16:49:08.086469818+00:00
-- finished_at: 2026-03-20T16:49:08.324576357+00:00
-- elapsed: 238ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c32871-0308-28d7-0023-c5530002fbba
-- desc: Get table schema
describe table "PC_DBT_DB"."DBT_EAPPEL"."STG_SNHD_INSPECTIONS";
-- created_at: 2026-03-20T16:49:09.121118941+00:00
-- finished_at: 2026-03-20T16:49:09.311724957+00:00
-- elapsed: 190ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.elvis.not_null_stg_snhd_inspections_violation_count.1f98e40c2e
-- query_id: 01c32871-0308-26c9-0023-c5530003f2a6
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select violation_count
from PC_DBT_DB.dbt_EAppel.stg_snhd_inspections
where violation_count is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.elvis.not_null_stg_snhd_inspections_violation_count.1f98e40c2e", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:49:09.173165482+00:00
-- finished_at: 2026-03-20T16:49:09.311719417+00:00
-- elapsed: 138ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.elvis.not_null_mart_restaurant_grades_total_inspections.13bb432ea6
-- query_id: 01c32871-0308-28d8-0023-c5530003e382
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select total_inspections
from PC_DBT_DB.dbt_EAppel.mart_restaurant_grades
where total_inspections is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.elvis.not_null_mart_restaurant_grades_total_inspections.13bb432ea6", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:49:09.179321684+00:00
-- finished_at: 2026-03-20T16:49:09.330880139+00:00
-- elapsed: 151ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.elvis.not_null_mart_inspections_over_time_inspection_month.0c38970b66
-- query_id: 01c32871-0308-2621-0023-c5530002cef2
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select inspection_month
from PC_DBT_DB.dbt_EAppel.mart_inspections_over_time
where inspection_month is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.elvis.not_null_mart_inspections_over_time_inspection_month.0c38970b66", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:49:09.148726527+00:00
-- finished_at: 2026-03-20T16:49:09.336986862+00:00
-- elapsed: 188ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.elvis.not_null_mart_top_violations_violation_code.271f25ddf4
-- query_id: 01c32871-0308-2621-0023-c5530002cefa
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select violation_code
from PC_DBT_DB.dbt_EAppel.mart_top_violations
where violation_code is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.elvis.not_null_mart_top_violations_violation_code.271f25ddf4", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:49:09.170764316+00:00
-- finished_at: 2026-03-20T16:49:09.339837852+00:00
-- elapsed: 169ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.elvis.not_null_mart_top_violations_occurrence_count.196cf3466e
-- query_id: 01c32871-0308-2621-0023-c5530002cef6
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select occurrence_count
from PC_DBT_DB.dbt_EAppel.mart_top_violations
where occurrence_count is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.elvis.not_null_mart_top_violations_occurrence_count.196cf3466e", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:49:09.227613425+00:00
-- finished_at: 2026-03-20T16:49:09.392752651+00:00
-- elapsed: 165ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.elvis.not_null_stg_snhd_inspections_serial_number.0350d88527
-- query_id: 01c32871-0308-28d8-0023-c5530003e386
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select serial_number
from PC_DBT_DB.dbt_EAppel.stg_snhd_inspections
where serial_number is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.elvis.not_null_stg_snhd_inspections_serial_number.0350d88527", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:49:09.207945674+00:00
-- finished_at: 2026-03-20T16:49:09.396203334+00:00
-- elapsed: 188ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.elvis.not_null_mart_restaurant_grades_permit_number.1918265f9e
-- query_id: 01c32871-0308-28d7-0023-c5530002fbbe
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select permit_number
from PC_DBT_DB.dbt_EAppel.mart_restaurant_grades
where permit_number is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.elvis.not_null_mart_restaurant_grades_permit_number.1918265f9e", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:49:09.186310705+00:00
-- finished_at: 2026-03-20T16:49:09.404993708+00:00
-- elapsed: 218ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.elvis.unique_mart_restaurant_grades_permit_number.8e384ad830
-- query_id: 01c32871-0308-24a8-0023-c5530002dca6
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    permit_number as unique_field,
    count(*) as n_records

from PC_DBT_DB.dbt_EAppel.mart_restaurant_grades
where permit_number is not null
group by permit_number
having count(*) > 1



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.elvis.unique_mart_restaurant_grades_permit_number.8e384ad830", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:49:09.253139700+00:00
-- finished_at: 2026-03-20T16:49:09.417802454+00:00
-- elapsed: 164ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.elvis.not_null_mart_inspections_over_time_inspection_count.52be5185c0
-- query_id: 01c32871-0308-28d8-0023-c5530003e38a
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select inspection_count
from PC_DBT_DB.dbt_EAppel.mart_inspections_over_time
where inspection_count is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.elvis.not_null_mart_inspections_over_time_inspection_count.52be5185c0", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:49:09.149608880+00:00
-- finished_at: 2026-03-20T16:49:09.501881517+00:00
-- elapsed: 352ms
-- outcome: success
-- dialect: snowflake
-- node_id: test.elvis.not_null_stg_snhd_inspections_permit_number.9a7b62a1f1
-- query_id: 01c32871-0308-238f-0023-c55300047112
-- desc: execute adapter call
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select permit_number
from PC_DBT_DB.dbt_EAppel.stg_snhd_inspections
where permit_number is null



  
  
      
    ) dbt_internal_test
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "test.elvis.not_null_stg_snhd_inspections_permit_number.9a7b62a1f1", "profile_name": "user", "target_name": "default"} */;

============================== 6cf40593-365e-4a95-a6bb-790b59c9a9b1 ==============================
-- created_at: 2026-03-20T16:54:31.388392024+00:00
-- finished_at: 2026-03-20T16:54:31.553262718+00:00
-- elapsed: 164ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c32876-0308-2467-0023-c55300026e8a
-- desc: execute adapter call
show terse schemas in database PC_DBT_DB
    limit 10000
/* {"app": "dbt", "connection_name": "", "dbt_version": "2.0.0", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:54:31.970518984+00:00
-- finished_at: 2026-03-20T16:54:32.196989185+00:00
-- elapsed: 226ms
-- outcome: success
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: 01c32876-0308-2a04-0023-c553000441be
-- desc: get_relation > list_relations call
SHOW OBJECTS IN SCHEMA "PC_DBT_DB"."DBT_EAPPEL" LIMIT 10000;
-- created_at: 2026-03-20T16:54:32.200062004+00:00
-- finished_at: 2026-03-20T16:54:33.132502036+00:00
-- elapsed: 932ms
-- outcome: success
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: 01c32876-0308-26c9-0023-c5530003f2b6
-- desc: execute adapter call
create table PC_DBT_DB.dbt_EAppel.violation_codes (VIOLATION_ID integer,VIOLATION_CODE integer,VIOLATION_DEMERITS integer,VIOLATION_DESCRIPTION varchar,OBJECTID integer)
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "seed.elvis.violation_codes", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:54:33.135473088+00:00
-- finished_at: 2026-03-20T16:54:33.279469403+00:00
-- elapsed: 143ms
-- outcome: success
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: 01c32876-0308-28d8-0023-c5530003e392
-- desc: add_query adapter call
BEGIN;
-- created_at: 2026-03-20T16:54:33.281551990+00:00
-- finished_at: 2026-03-20T16:54:34.535989485+00:00
-- elapsed: 1.3s
-- outcome: error
-- error vendor code: 100038
-- error message: Internal: [Snowflake] 100038 (22018): DML operation to table PC_DBT_DB.DBT_EAPPEL.VIOLATION_CODES failed on column VIOLATION_CODE with error: Numeric value '1-Jun' is not recognized
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: not available
-- desc: add_query adapter call
insert into PC_DBT_DB.dbt_EAppel.violation_codes (VIOLATION_ID, VIOLATION_CODE, VIOLATION_DEMERITS, VIOLATION_DESCRIPTION, OBJECTID) values
            ('1','1','6','Food not obtained from approved sources and/or improperly identified.','7972'),('2','2','6','Food spoiled or adulterated.','7973'),('3','3','6','Employee(s) working with boils,infected wounds,respiratory,infections and/or other communicable diseases.,','7974'),('4','4','4','Inadequate hot and cold holding equipment,improperly designed,maintained and/or operated.,','7975'),('5','5','10','Hot potentially hazardous foods not rapidly cooled by approved methods.,,','7976'),('7','7','2','Potentially hazardous foods improperly thawed.,','7977'),('8','8','3','Potentially hazardous salads and/or fillings not made with prechilled ingredients.,','7978'),('9','9','2','Perishable foods kept at improper temperature.,','7979'),('10','10','3','Suitable thermometers (stem,cooler,oven) not provided and/or inadequately used.,','7980'),('12','12','6','Food workers improperly washing hands after using toilet,coughing,eating,smoking,after handling raw animal products and/or otherwise contaminating their hands.Inadequatefacilities.,','7981'),('13','13','3','Unsuitable hand washing facilities,unclean,inaccessible and/or not in good repair,with unapproved soap,towels and/or waste receptacles not provided.,','7982'),('14','14','4','Kitchenware and/or food contact surfaces of equipment improperly cleaned,sanitized and/or air dried.,,','7983'),('15','15','6','Sewage not disposed into public sewer or approved facility. Cross-connections or back siphonage present.,','7984'),('16','16','6','No hot and cold running water as required and/or water not from an approved source.,','7985'),('17','17','2','Fruits and vegetables improperly washed prior to serving.,','7986'),('18','18','1','Foods not stored off the floor.,','7987'),('19','19','1','Required labels not present on food or containers of food.Required signs not posted.,','7988'),('20','20','1','Health cards not current on all food handlers.,','7989'),('21','21','1','Unacceptable hygienic practices,unclean outer garments,improper hair restraints used.,','7990'),('22','22','1','In-use utensils improperly handled and/or stored.,','7991'),('23','23','1','Facilities for washing and sanitizing equipment and utensils unapproved,inadequate,improperly constructed,maintained and/or operated.,,','7992'),('24','24','1','Accurate thermometers,chemical tests kits,and/or pressure gauges not present and/or working.,','7993'),('25','25','1','Clean utensils,equipment and/or singe service items improperly handled,stored and/or dispensed.,','7994'),('26','26','3','Single service items reused.,','7995'),('27','27','1','Unclean wiping cloths,stored in an unapproved sanitizer,and/or unrestricted in use.,','7996'),('28','28','1','Unapproved food contact surfaces. Food contact surfaces notsmooth,easily cleanable,properly constructed and/or installed.,','7997'),('29','29','1','Plastic used for food contact surfaces is not of approved food grade quality.,','7998'),('30','30','1','Non-food contact surfaces improperly constructed and/or installed.,','7999'),('31','31','1','Non-food contact surfaces and/or cooking devices not maintained and/or unclean.,','8000'),('32','32','1','Toilet facilities for employees inadequate,inconvenient,unclean and/or not in good repair.Covered trash cans not provided.Doors not self-closing.,','8001'),('33','33','1','Garbage storage and/or removal inadequate and/or unclean.Garbage containers not clean,pest proof,non-absorbent and covered.Wash area unclean and/or not maintained.,','8002'),('34','34','3','No effective measures to control pests.Pest control devices not maintained.,','8003'),('35','35','1','Improper lighting and/or ventilation,ventilation hoods and/or filters improperly cleaned and/or maintained.,,','8004'),('36','36','1','Plumbing and/or fixtures improperly sized,installed and/or maintained. Plumbing and/or fixtures improperly drained.,,','8005'),('37','37','1','Floors,walls,ceilings,improperly constructed and/or installed.Not in good repair and/or clean.,,','8006'),('38','38','1','Living quarters not completely separated from food service.Infant or child care allowed.Premises not maintained free of litter,unnecessary equipment and/or personal effects.,,','8007'),('39','39','1','Live animals not in compliance with current Regulations.,','8008'),('40','40','1','Non-compliant with Nevada Revised Statute 202.2483 regarding smoking.,','8009'),('61','1-Jun','6','Poultry,poultry stuffing,stuffed meats,stuffing containing meats,casseroles containing potentially hazardous foods and/or food to be reheated containing potentially hazardous food not cooked to an internal temperature of 165°F.,','8010'),('62','2-Jun','6','Ground,fabricated and/or restructured meats not cooked throughout to 155&deg,F.,','8011'),('63','3-Jun','6','Pork and/or any food containing pork,not cooked to an internal temperature of 155&deg,F or above.,','8012'),('64','4-Jun','6','Potentially hazardous foods not kept at 40&deg,F or colder or at 140&deg,F or hotter,except during necessary preparation procedures.,,','8013'),('111','1-Nov','4','Food unprotected from cross-contamination by raw meats,poultry,fish,seafood and/or raw eggs.,,','8014'),('112','2-Nov','4','Food unprotected from cross-contamination by food handlers.,','8015'),('113','3-Nov','4','Food unprotected from cross-contamination by chemicals.,','8016'),('114','4-Nov','4','Food unprotected by cross-contamination by proper storage.,','8017'),('201','1','5','Verifiable time as a control with approved procedure when in use. Operational plan,HACCP plan,waiver or variance approved and followed when required. Nevada Clean Indoor Air Act compliant.,','8018'),('202','2','5','Handwashing (as required,when required,proper glove use,no bare hand contact of ready to eat foods).Foodhandler health restrictions as required.,,','8019'),('203','3','5','Commercially manufactured food from approved source with required labels. Parasite destruction as required. Potentially hazardous foods/time temperature control for safety (PHF/TCS) received at proper temperature.,','8020'),('204','4','5','Hot and cold running water from approved source as required.,','8021'),('205','5','5','Imminently dangerous cross connection or backflow.Waste water and sewage disposed into public sewer or approved facility.,','8022'),('206','6','5','Food wholesome,not spoiled,contaminated,or adulterated.,,','8023'),('207','7','5','PHF/TCSs cooked and reheated to proper temperatures.,','8024'),('208','8','5','PHF/TCSs properly cooled.,','8025'),('209','9','5','PHF/TCSs at proper temperatures during storage,display,service,transport,and holding. ,','8026'),('210','10','5','Operating within the parameters of the health permit.,','8027'),('211','11','3','Food protected from potential contamination during storage and preparation.,','8028'),('212','12','3','Food protected from potential contamination by chemicals. Toxic items properly labeled,stored and used.,,','8029'),('213','13','3','Food protected from potential contamination by employees and consumers.,','8030'),('214','14','3','Kitchenware and food contact surfaces of equipment properly washed,rinsed,sanitized and air dried.Sanitizer solution provided and maintained as required.,','8031'),('215','15','3','Handwashing facilities adequate in number,stocked,accessible,and limited to handwashing only.,,','8032'),('216','16','3','Effective pest control measures. Animals restricted as required.,','8033'),('217','17','3','Hot and cold holding equipment present,properly designed,maintained and operated.,','8034'),('218','18','3','Accurate thermometers (stem & hot/cold holding) provided and used.,','8035'),('219','19','3','PHF/TCSs properly thawed.,','8036'),('220','20','3','Single use items not reused or misused.,','8037'),('221','21','3','Person in charge available and knowledgeable/management certification.,','8038'),('222','22','3','Backflow prevention devices and methods in place and maintained.,','8039'),('223','23','3','B or C" grade card and required signs posted conspicuously. Consumer advisory as required. Records/logs maintained and available when required.,"','8040'),('224','24','1','Acceptable personal hygiene practices,clean outer garments,proper hair restraints used. Living quarters and child care completely separated from food service.,','8041'),('225','25','1','Food and food storage containers properly labeled and dated as required. Food stored off the floor when required. Non-PHF/TCS not spoiled and within shelf-life. Proper retail storage of chemicals.,','8042'),('226','26','1','Facilities for washing and sanitizing kitchenware approved,adequate,properly constructed,maintained and operated. ,,','8043'),('227','27','1','Appropriate sanitizer test kits provided and used. Ware washing thermometer(s) as required. Wiping cloths & linens stored and used properly.,','8044'),('228','28','1','Food contact surfaces and equipment approved,food grade material,smooth,easily cleanable,properly constructed and installed.,','8045'),('229','29','1','Utensils,equipment,and single serve items properly handled,stored,and dispensed.,','8046'),('230','30','1','Nonfood contact surfaces and equipment properly constructed,installed,maintained and clean.,','8047'),('231','31','1','Health cards as required. Foodhandler not aware of employee health policy. A" grade card posted conspicuously. ,"','8048'),('232','32','1','Restrooms,mop sink,and custodial areas maintained and clean.Premises maintained free of litter,unnecessary equipment,or personal effects. Trash areas adequate,pest proof,and clean.','8049'),('233','33','1','Facility in sound condition and maintained (floors,walls,ceilings,plumbing,lighting,ventilation,etc.).','8050'),('234','34','1','Fruits and vegetables washed prior to preparation or service.,','8051'),('301','IHH-1','0','Imminent Health Hazard - (Immediate Closure) - Interruption of electrical service,','8052'),('302','IHH-2','0','Imminent Health Hazard - (Immediate Closure) - No potable water or hot water,','8053'),('303','IHH-3','0','Imminent Health Hazard - (Immediate Closure) - Gross unsanitary occurrences or conditions including pest infestation,','8054'),('304','IHH-4','0','Imminent Health Hazard - (Immediate Closure) - Sewage or liquid waste not disposed of in an approved manner,','8055'),('305','IHH-5','0','Imminent Health Hazard - (Immediate Closure) - Lack of adequate refrigeration,','8056'),('306','IHH-6','0','Imminent Health Hazard - (Immediate Closure) - Lack of adequate employee toilets and handwashing facilities,','8057'),('307','IHH-7','0','Imminent Health Hazard - (Immediate Closure) - Misuse of poisonous or toxic materials,','8058'),('308','IHH-8','0','Imminent Health Hazard - (Immediate Closure) - Suspected foodborne illness outbreak,','8059'),('309','IHH-9','0','Imminent Health Hazard - (Immediate Closure) - Emergency such as fire and/or flood,','8060'),('310','IHH-10','0','Imminent Health Hazard - (Immediate Closure) - Other condition or circumstance that may endanger public health,','8061'),('2907','2907','3','Food and warewashing equipment approved,properly designed,constructed and installed.,','8062'),('2908','2908','3','PHF/TCSs properly thawed. Fruits and vegetables washed prior to preparation or service.,','8063'),('2909','2909','3','Grade/card signs posted. Consumer advisory. Records/logs. NCIAA. PHFs labeled/dated. Offsite label.,','8064'),('2910','2910','0','Non-PHF labeled/dated/not spoiled/within shelf-life. Food stored off-floor. Retail chemical storage.,','8065'),('2911','2911','0','Sanitizer kits available. Equip. & ware washing therm. as required. Wiping cloths and linen use.,','8066'),('2912','2912','0','Small wares and portable appliances approved,properly designed,in good repair.,','8067'),('2925','2925','0','Acceptable personal hygiene,clean garments,hair restraints. Living quarters & child care separate.,','8068'),('2926','2926','0','Ware washing facilities approved,adequate,properly constructed,maintained & operated.,,','8069'),('2927','2927','0','Utensils,equipment,and single serve items properly handled,stored,and dispensed.,','8070'),('2928','2928','0','Nonfood contact surfaces and equipment properly constructed,installed,maintained and clean.,','8071'),('2929','2929','0','RR''s,mop sk,cust. areasclean/maint. No litter,unnec. equip,pers items. Trash area clean/maint.,','8072'),('2930','2930','0','Facility maintained (floors,walls,ceilings,plumbing,lighting,ventilation,etc.).','8073'),('2931','2931','0','Time as a control. Operational plan,waiver/variance followed. Permit parameters followed.,,','8074'),('2932','2932','0','Hand washing as required,no bare hand w/ RTE foods. Foodhandler health restrictions as required.,,','8075'),('2933','2933','0','Food from an approved source w/ proper labels. Parasite destruction. PHF''s received @ proper temp.,','8076'),('2934','2934','0','Hot & cold running water from an approved source as required.,','8077'),('2935','2935','0','Imminently dangerous cross connection or backflow. Waste water and sewage properly disposed of.,','8078'),('2936','2936','0','Food wholesome,not spoiled,contaminated,or adulterated.,,','8079'),('2937','2937','0','PHF/TCSs cooked and reheated to proper temperature.,','8080'),('2938','2938','0','PHF/TCSs properly cooled.,','8081'),('2939','2939','0','PHF/TCSs maintained at proper temperature.,','8082'),('2940','2940','0','Food protected from potential contamination during storage and preparation.,','8083'),('2941','2941','0','Food protected from potential contamination by chemicals. Toxic items labeled,stored & used.,,','8084'),('2942','2942','0','Food protected from potential contamination by employees and consumers.,','8085'),('2943','2943','0','Kitchenware & FCS of equip. properly washed,rinsed,san. & air dried. San solution as required.,','8086'),('2944','2944','0','Handwashing facilities adequate in number,stocked,accessible,and limited to handwashing only.,,','8087'),('2945','2945','0','Effective pest control measures. Animals restricted as required.,','8088'),('2946','2946','0','Hot and cold holding equipment present,properly designed,maintained and operated.,','8089'),('2947','2947','0','Accurate thermometers (stem & hot/cold holding) provided and used.,','8090'),('2948','2948','0','Single use items not reused or misused.,','8091'),('2949','2949','0','Person in charge available and knowledgeable/management certification.,','8092'),('2950','2950','0','Backflow prevention devices and methods in place and maintained.,','8093'),('2951','2951','0','Food and warewashing equipment approved,properly designed,constructed and installed.,','8094'),('2952','2952','0','PHF/TCSs properly thawed. Fruits and vegetables washed prior to preparation of service.,','8095'),('2953','2953','0','Grade card/signs posted. Consumer advisory. Records/logs. NCIAA. PHFs labeled/dated. Offsite label.,','8096'),('2954','2954','5','Time as a control. Operational plan,waiver/variance followed. Permit parameters followed.,,','8097'),('2955','2955','3','Kitchenware & FCS of equip. properly washed,rinsed,san. & air dried. San solution as required.,','8098'),('2956','2956','3','Person in charge available and knowledgeable/management certification,','8099'),('3046','3046','5','Approved water source with required documentation.,','8100'),('3047','3047','5','Required E-Coli lab testing documented. (NAC 445A.555 a),','8101'),('3048','3048','5','Required Annual & 4-year series lab testing documented. (NAC 445A. 555 b&c),','8102'),('3049','3049','3','Container testing conducted every three months. (NAC 445A.563),','8103'),('3050','3050','3','Pre and Post Water testing conducted as required. ( NAC445A.557),','8104'),('3064','3064','3','Proper labeling of food for consumption off site and/or transportation.,','8105'),('3065','3065','3','Person in charge available and knowledgeable/management certification.Facility has an effective employee health policy.,','8106'),('3066','3066','3','Grade card and required signs posted conspicuously. Records/logs maintained and available when required. NCIAA compliant.,','8107'),('3067','3067','0','Appropriate sanitizer test kits provided and used. Ware washing thermometer(s) are required. Wiping cloths and linens stored and used properly. Permanently affixed thermometers.,','8108'),('3068','3068','0','Facility in sound condition and maintained (floors,walls,ceilings,plumbing,lighting,ventilation,etc.)','8109'),('3069','3069','5','Operational plan,HACCP plan,waiver or variance approved and followed when required. Operating within the parameters of the health permit.,','8110'),('4177','4177','0','Dumpsters lids open,','8111'),('4178','4178','0','Dumpsters located less than 50 ft from doors,','8112'),('4179','4179','0','Dumpster on soil or damaged pavement,','8113'),('4180','4180','0','Trash spillage around dumpsters,','8114'),('4181','4181','0','Outdoor trash cans with no lids,','8115'),('4182','4182','0','Weatherstripping and/or door sweeps in disrepair,','8116'),('4183','4183','0','Windows damaged and/or screens missing,','8117'),('4184','4184','0','Penetrations not sealed,','8118'),('4185','4185','0','Walls/roof line in disrepair,','8119'),('4186','4186','0','Ventilation intakes not screened,','8120'),('4187','4187','0','Water not adequately draining,','8121'),('4188','4188','0','Roof in disrepair,','8122'),('4189','4189','0','Gutters clogged,','8123'),('4190','4190','0','Other,','8124'),('4191','4191','0','Overgrown/Excessive vegetation,','8125'),('4192','4192','0','Trees/Vegetation in contact with building,','8126'),('4193','4193','0','Tree hazard observed,','8127'),('4194','4194','0','Overgrown/Excessive vegetation,','8128'),('4195','4195','0','Evidence of rodents,','8129'),('4196','4196','0','Evidence of nuisance birds,','8130'),('4197','4197','0','Other,','8131'),('4198','4198','0','General unsanitary conditions observed,','8132'),('4199','4199','0','General unsanitary conditions observed,','8133'),('4200','4200','0','General unsanitary conditions observed,','8134'),('4201','4201','0','General unsanitary conditions observed,','8135'),('4202','4202','0','Other,','8136'),('4203','4203','0','Evidence of rodents,','8137'),('4204','4204','0','Evidence of flies,','8138'),('4205','4205','0','Evidence of cockroaches,','8139'),('4206','4206','0','Other,','8140'),('4207','4207','0','Administrative procedures not followed as required,','8141'),('4208','4208','0','Sticky traps not serviced as needed,','8142'),('4209','4209','0','Light traps not serviced as needed,','8143'),('4210','4210','0','Bait stations not serviced as needed,','8144'),('4771','4771','0','Interruption of electrical service,','8145'),('4772','4772','0','No potable water or hot water,','8146'),('4773','4773','0','Gross unsanitary occurrences or conditions including pest infestation,','8147'),('4774','4774','0','Sewage or liquid waste not disposed of in an approved manner,','8148'),('4775','4775','0','Lack of adequate refrigeration,','8149'),('4776','4776','0','Lack of adequate employee toilets and handwashing facilities,','8150'),('4777','4777','0','Suspected foodborne illness outbreak,','8151'),('4778','4778','0','Other condition or circumstance that may endanger public health,','8152'),('4779','4779','5','Operating within the parameters of the health permit. Compliance with Time as a Public Health Control,waiver,specialized process,and Hazard Analysis Critical Control Point (HACCP) plan.,,','8153'),('4780','4780','5','Handwashing (as required,when required,proper glove use,no bare hand contact of ready to eat foods). Food handler health restrictions as required.,,','8154'),('4781','4781','5','Commercially manufactured food from approved source with required labels. Parasite destruction as required. Time temperature control for safety (TCS) food received at proper temperature.,','8155'),('4782','4782','5','Hot and cold running water from approved source as required.,','8156'),('4783','4783','5','No imminently dangerous cross connection,adequate backflow prevention. Wastewater and sewage properly disposed.,,','8157'),('4784','4784','5','Food wholesome,not spoiled,contaminated,or adulterated.,,','8158'),('4785','4785','5','TCS food cooked and reheated to proper temperatures.,','8159'),('4786','4786','5','TCS food properly cooled.,','8160'),('4787','4787','5','TCS food at proper temperatures.,','8161'),('4788','4788','3','Equipment approved,properly designed,maintained,and operated.,,','8162'),('4789','4789','3','Food protected from potential cross-contamination.,','8163'),('4790','4790','3','Chemicals properly identified,stored,and used.,','8164'),('4791','4791','3','Food protected from potential contamination by employees and consumers.,','8165'),('4792','4792','3','Food contact surfaces of equipment properly cleaned and sanitized. Sanitizer solution provided and maintained as required.,','8166'),('4793','4793','3','Adequate handwashing sinks stocked and accessible.,','8167'),('4794','4794','3','Effective pest control measures. Animals restricted as required.,','8168'),('4795','4795','3','Grade card posted conspicuously. Consumer advisory as required.,','8169'),('4796','4796','3','Thermometers provided and accurate.,','8170'),('4797','4797','3','TCS food thawed and cooled using proper methods. Fruits and vegetables washed prior to preparation or service.,','8171'),('4798','4798','3','Single-use/single-service items properly used.,','8172'),('4799','4799','3','Person in charge present,demonstrates knowledge,and performs duties. Effective employee health policy. Mandated certification and food handler card as required.,','8173'),('4800','4800','3','Proper backflow prevention devices in place and maintained.,','8174'),('4801','4801','3','TCS food labeled and dated as required. Food sold for offsite consumption labeled properly. Records,logs,policies,and procedures maintained and available when required.,,','8175'),('4802','4802','0','Personal cleanliness maintained. Personal effects properly stored.,','8176'),('4803','4803','0','Non-TCS food labeled and within shelf-life. Food stored off the floor. Proper retail storage of chemicals.,','8177'),('4804','4804','0','Ware washing facilities maintained. Wiping cloths properly stored,test strips available.,,','8178'),('4805','4805','0','Signs and certifications as required.,','8179'),('4806','4806','0','Small wares approved,properly designed,in good repair.,','8180'),('4807','4807','0','Utensils,equipment,linens,single-service/single-use items properly handled,stored,and dispensed.,','8181'),('4808','4808','0','Nonfood contact surfaces and equipment properly constructed,installed,maintained,and clean.,,','8182'),('4809','4809','0','Restrooms custodial areas,and premises maintained.,','8183'),('4810','4810','0','Physical facility in sound condition and maintained.,','8184');

============================== 243d3271-794f-418d-aa54-fb6253e5ac48 ==============================
-- created_at: 2026-03-20T16:55:11.875916749+00:00
-- finished_at: 2026-03-20T16:55:12.013074504+00:00
-- elapsed: 137ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c32877-0308-2a04-0023-c553000441c2
-- desc: execute adapter call
show terse schemas in database PC_DBT_DB
    limit 10000
/* {"app": "dbt", "connection_name": "", "dbt_version": "2.0.0", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:55:12.558818310+00:00
-- finished_at: 2026-03-20T16:55:12.889345963+00:00
-- elapsed: 330ms
-- outcome: success
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: 01c32877-0308-26c9-0023-c5530003f2c2
-- desc: get_relation > list_relations call
SHOW OBJECTS IN SCHEMA "PC_DBT_DB"."DBT_EAPPEL" LIMIT 10000;
-- created_at: 2026-03-20T16:55:12.891569253+00:00
-- finished_at: 2026-03-20T16:55:13.105961915+00:00
-- elapsed: 214ms
-- outcome: success
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: 01c32877-0308-28d8-0023-c5530003e396
-- desc: execute adapter call
begin
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "seed.elvis.violation_codes", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:55:13.106161457+00:00
-- finished_at: 2026-03-20T16:55:13.411576412+00:00
-- elapsed: 305ms
-- outcome: success
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: 01c32877-0308-2621-0023-c5530002cf0e
-- desc: execute adapter call

    
    truncate table "PC_DBT_DB"."DBT_EAPPEL"."VIOLATION_CODES"
  
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "seed.elvis.violation_codes", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:55:13.411863110+00:00
-- finished_at: 2026-03-20T16:55:14.218262540+00:00
-- elapsed: 806ms
-- outcome: success
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: 01c32877-0308-238f-0023-c5530004712a
-- desc: execute adapter call

    commit
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "seed.elvis.violation_codes", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:55:14.221068742+00:00
-- finished_at: 2026-03-20T16:55:14.533373799+00:00
-- elapsed: 312ms
-- outcome: success
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: 01c32877-0308-2467-0023-c55300026e8e
-- desc: add_query adapter call
BEGIN;
-- created_at: 2026-03-20T16:55:14.535598399+00:00
-- finished_at: 2026-03-20T16:55:15.247046563+00:00
-- elapsed: 711ms
-- outcome: error
-- error vendor code: 100038
-- error message: Internal: [Snowflake] 100038 (22018): DML operation to table PC_DBT_DB.DBT_EAPPEL.VIOLATION_CODES failed on column VIOLATION_CODE with error: Numeric value '1-Jun' is not recognized
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: not available
-- desc: add_query adapter call
insert into PC_DBT_DB.dbt_EAppel.violation_codes (VIOLATION_ID, VIOLATION_CODE, VIOLATION_DEMERITS, VIOLATION_DESCRIPTION, OBJECTID) values
            ('1','1','6','Food not obtained from approved sources and/or improperly identified.','7972'),('2','2','6','Food spoiled or adulterated.','7973'),('3','3','6','Employee(s) working with boils,infected wounds,respiratory,infections and/or other communicable diseases.,','7974'),('4','4','4','Inadequate hot and cold holding equipment,improperly designed,maintained and/or operated.,','7975'),('5','5','10','Hot potentially hazardous foods not rapidly cooled by approved methods.,,','7976'),('7','7','2','Potentially hazardous foods improperly thawed.,','7977'),('8','8','3','Potentially hazardous salads and/or fillings not made with prechilled ingredients.,','7978'),('9','9','2','Perishable foods kept at improper temperature.,','7979'),('10','10','3','Suitable thermometers (stem,cooler,oven) not provided and/or inadequately used.,','7980'),('12','12','6','Food workers improperly washing hands after using toilet,coughing,eating,smoking,after handling raw animal products and/or otherwise contaminating their hands.Inadequatefacilities.,','7981'),('13','13','3','Unsuitable hand washing facilities,unclean,inaccessible and/or not in good repair,with unapproved soap,towels and/or waste receptacles not provided.,','7982'),('14','14','4','Kitchenware and/or food contact surfaces of equipment improperly cleaned,sanitized and/or air dried.,,','7983'),('15','15','6','Sewage not disposed into public sewer or approved facility. Cross-connections or back siphonage present.,','7984'),('16','16','6','No hot and cold running water as required and/or water not from an approved source.,','7985'),('17','17','2','Fruits and vegetables improperly washed prior to serving.,','7986'),('18','18','1','Foods not stored off the floor.,','7987'),('19','19','1','Required labels not present on food or containers of food.Required signs not posted.,','7988'),('20','20','1','Health cards not current on all food handlers.,','7989'),('21','21','1','Unacceptable hygienic practices,unclean outer garments,improper hair restraints used.,','7990'),('22','22','1','In-use utensils improperly handled and/or stored.,','7991'),('23','23','1','Facilities for washing and sanitizing equipment and utensils unapproved,inadequate,improperly constructed,maintained and/or operated.,,','7992'),('24','24','1','Accurate thermometers,chemical tests kits,and/or pressure gauges not present and/or working.,','7993'),('25','25','1','Clean utensils,equipment and/or singe service items improperly handled,stored and/or dispensed.,','7994'),('26','26','3','Single service items reused.,','7995'),('27','27','1','Unclean wiping cloths,stored in an unapproved sanitizer,and/or unrestricted in use.,','7996'),('28','28','1','Unapproved food contact surfaces. Food contact surfaces notsmooth,easily cleanable,properly constructed and/or installed.,','7997'),('29','29','1','Plastic used for food contact surfaces is not of approved food grade quality.,','7998'),('30','30','1','Non-food contact surfaces improperly constructed and/or installed.,','7999'),('31','31','1','Non-food contact surfaces and/or cooking devices not maintained and/or unclean.,','8000'),('32','32','1','Toilet facilities for employees inadequate,inconvenient,unclean and/or not in good repair.Covered trash cans not provided.Doors not self-closing.,','8001'),('33','33','1','Garbage storage and/or removal inadequate and/or unclean.Garbage containers not clean,pest proof,non-absorbent and covered.Wash area unclean and/or not maintained.,','8002'),('34','34','3','No effective measures to control pests.Pest control devices not maintained.,','8003'),('35','35','1','Improper lighting and/or ventilation,ventilation hoods and/or filters improperly cleaned and/or maintained.,,','8004'),('36','36','1','Plumbing and/or fixtures improperly sized,installed and/or maintained. Plumbing and/or fixtures improperly drained.,,','8005'),('37','37','1','Floors,walls,ceilings,improperly constructed and/or installed.Not in good repair and/or clean.,,','8006'),('38','38','1','Living quarters not completely separated from food service.Infant or child care allowed.Premises not maintained free of litter,unnecessary equipment and/or personal effects.,,','8007'),('39','39','1','Live animals not in compliance with current Regulations.,','8008'),('40','40','1','Non-compliant with Nevada Revised Statute 202.2483 regarding smoking.,','8009'),('61','1-Jun','6','Poultry,poultry stuffing,stuffed meats,stuffing containing meats,casseroles containing potentially hazardous foods and/or food to be reheated containing potentially hazardous food not cooked to an internal temperature of 165°F.,','8010'),('62','2-Jun','6','Ground,fabricated and/or restructured meats not cooked throughout to 155&deg,F.,','8011'),('63','3-Jun','6','Pork and/or any food containing pork,not cooked to an internal temperature of 155&deg,F or above.,','8012'),('64','4-Jun','6','Potentially hazardous foods not kept at 40&deg,F or colder or at 140&deg,F or hotter,except during necessary preparation procedures.,,','8013'),('111','1-Nov','4','Food unprotected from cross-contamination by raw meats,poultry,fish,seafood and/or raw eggs.,,','8014'),('112','2-Nov','4','Food unprotected from cross-contamination by food handlers.,','8015'),('113','3-Nov','4','Food unprotected from cross-contamination by chemicals.,','8016'),('114','4-Nov','4','Food unprotected by cross-contamination by proper storage.,','8017'),('201','1','5','Verifiable time as a control with approved procedure when in use. Operational plan,HACCP plan,waiver or variance approved and followed when required. Nevada Clean Indoor Air Act compliant.,','8018'),('202','2','5','Handwashing (as required,when required,proper glove use,no bare hand contact of ready to eat foods).Foodhandler health restrictions as required.,,','8019'),('203','3','5','Commercially manufactured food from approved source with required labels. Parasite destruction as required. Potentially hazardous foods/time temperature control for safety (PHF/TCS) received at proper temperature.,','8020'),('204','4','5','Hot and cold running water from approved source as required.,','8021'),('205','5','5','Imminently dangerous cross connection or backflow.Waste water and sewage disposed into public sewer or approved facility.,','8022'),('206','6','5','Food wholesome,not spoiled,contaminated,or adulterated.,,','8023'),('207','7','5','PHF/TCSs cooked and reheated to proper temperatures.,','8024'),('208','8','5','PHF/TCSs properly cooled.,','8025'),('209','9','5','PHF/TCSs at proper temperatures during storage,display,service,transport,and holding. ,','8026'),('210','10','5','Operating within the parameters of the health permit.,','8027'),('211','11','3','Food protected from potential contamination during storage and preparation.,','8028'),('212','12','3','Food protected from potential contamination by chemicals. Toxic items properly labeled,stored and used.,,','8029'),('213','13','3','Food protected from potential contamination by employees and consumers.,','8030'),('214','14','3','Kitchenware and food contact surfaces of equipment properly washed,rinsed,sanitized and air dried.Sanitizer solution provided and maintained as required.,','8031'),('215','15','3','Handwashing facilities adequate in number,stocked,accessible,and limited to handwashing only.,,','8032'),('216','16','3','Effective pest control measures. Animals restricted as required.,','8033'),('217','17','3','Hot and cold holding equipment present,properly designed,maintained and operated.,','8034'),('218','18','3','Accurate thermometers (stem & hot/cold holding) provided and used.,','8035'),('219','19','3','PHF/TCSs properly thawed.,','8036'),('220','20','3','Single use items not reused or misused.,','8037'),('221','21','3','Person in charge available and knowledgeable/management certification.,','8038'),('222','22','3','Backflow prevention devices and methods in place and maintained.,','8039'),('223','23','3','B or C" grade card and required signs posted conspicuously. Consumer advisory as required. Records/logs maintained and available when required.,"','8040'),('224','24','1','Acceptable personal hygiene practices,clean outer garments,proper hair restraints used. Living quarters and child care completely separated from food service.,','8041'),('225','25','1','Food and food storage containers properly labeled and dated as required. Food stored off the floor when required. Non-PHF/TCS not spoiled and within shelf-life. Proper retail storage of chemicals.,','8042'),('226','26','1','Facilities for washing and sanitizing kitchenware approved,adequate,properly constructed,maintained and operated. ,,','8043'),('227','27','1','Appropriate sanitizer test kits provided and used. Ware washing thermometer(s) as required. Wiping cloths & linens stored and used properly.,','8044'),('228','28','1','Food contact surfaces and equipment approved,food grade material,smooth,easily cleanable,properly constructed and installed.,','8045'),('229','29','1','Utensils,equipment,and single serve items properly handled,stored,and dispensed.,','8046'),('230','30','1','Nonfood contact surfaces and equipment properly constructed,installed,maintained and clean.,','8047'),('231','31','1','Health cards as required. Foodhandler not aware of employee health policy. A" grade card posted conspicuously. ,"','8048'),('232','32','1','Restrooms,mop sink,and custodial areas maintained and clean.Premises maintained free of litter,unnecessary equipment,or personal effects. Trash areas adequate,pest proof,and clean.','8049'),('233','33','1','Facility in sound condition and maintained (floors,walls,ceilings,plumbing,lighting,ventilation,etc.).','8050'),('234','34','1','Fruits and vegetables washed prior to preparation or service.,','8051'),('301','IHH-1','0','Imminent Health Hazard - (Immediate Closure) - Interruption of electrical service,','8052'),('302','IHH-2','0','Imminent Health Hazard - (Immediate Closure) - No potable water or hot water,','8053'),('303','IHH-3','0','Imminent Health Hazard - (Immediate Closure) - Gross unsanitary occurrences or conditions including pest infestation,','8054'),('304','IHH-4','0','Imminent Health Hazard - (Immediate Closure) - Sewage or liquid waste not disposed of in an approved manner,','8055'),('305','IHH-5','0','Imminent Health Hazard - (Immediate Closure) - Lack of adequate refrigeration,','8056'),('306','IHH-6','0','Imminent Health Hazard - (Immediate Closure) - Lack of adequate employee toilets and handwashing facilities,','8057'),('307','IHH-7','0','Imminent Health Hazard - (Immediate Closure) - Misuse of poisonous or toxic materials,','8058'),('308','IHH-8','0','Imminent Health Hazard - (Immediate Closure) - Suspected foodborne illness outbreak,','8059'),('309','IHH-9','0','Imminent Health Hazard - (Immediate Closure) - Emergency such as fire and/or flood,','8060'),('310','IHH-10','0','Imminent Health Hazard - (Immediate Closure) - Other condition or circumstance that may endanger public health,','8061'),('2907','2907','3','Food and warewashing equipment approved,properly designed,constructed and installed.,','8062'),('2908','2908','3','PHF/TCSs properly thawed. Fruits and vegetables washed prior to preparation or service.,','8063'),('2909','2909','3','Grade/card signs posted. Consumer advisory. Records/logs. NCIAA. PHFs labeled/dated. Offsite label.,','8064'),('2910','2910','0','Non-PHF labeled/dated/not spoiled/within shelf-life. Food stored off-floor. Retail chemical storage.,','8065'),('2911','2911','0','Sanitizer kits available. Equip. & ware washing therm. as required. Wiping cloths and linen use.,','8066'),('2912','2912','0','Small wares and portable appliances approved,properly designed,in good repair.,','8067'),('2925','2925','0','Acceptable personal hygiene,clean garments,hair restraints. Living quarters & child care separate.,','8068'),('2926','2926','0','Ware washing facilities approved,adequate,properly constructed,maintained & operated.,,','8069'),('2927','2927','0','Utensils,equipment,and single serve items properly handled,stored,and dispensed.,','8070'),('2928','2928','0','Nonfood contact surfaces and equipment properly constructed,installed,maintained and clean.,','8071'),('2929','2929','0','RR''s,mop sk,cust. areasclean/maint. No litter,unnec. equip,pers items. Trash area clean/maint.,','8072'),('2930','2930','0','Facility maintained (floors,walls,ceilings,plumbing,lighting,ventilation,etc.).','8073'),('2931','2931','0','Time as a control. Operational plan,waiver/variance followed. Permit parameters followed.,,','8074'),('2932','2932','0','Hand washing as required,no bare hand w/ RTE foods. Foodhandler health restrictions as required.,,','8075'),('2933','2933','0','Food from an approved source w/ proper labels. Parasite destruction. PHF''s received @ proper temp.,','8076'),('2934','2934','0','Hot & cold running water from an approved source as required.,','8077'),('2935','2935','0','Imminently dangerous cross connection or backflow. Waste water and sewage properly disposed of.,','8078'),('2936','2936','0','Food wholesome,not spoiled,contaminated,or adulterated.,,','8079'),('2937','2937','0','PHF/TCSs cooked and reheated to proper temperature.,','8080'),('2938','2938','0','PHF/TCSs properly cooled.,','8081'),('2939','2939','0','PHF/TCSs maintained at proper temperature.,','8082'),('2940','2940','0','Food protected from potential contamination during storage and preparation.,','8083'),('2941','2941','0','Food protected from potential contamination by chemicals. Toxic items labeled,stored & used.,,','8084'),('2942','2942','0','Food protected from potential contamination by employees and consumers.,','8085'),('2943','2943','0','Kitchenware & FCS of equip. properly washed,rinsed,san. & air dried. San solution as required.,','8086'),('2944','2944','0','Handwashing facilities adequate in number,stocked,accessible,and limited to handwashing only.,,','8087'),('2945','2945','0','Effective pest control measures. Animals restricted as required.,','8088'),('2946','2946','0','Hot and cold holding equipment present,properly designed,maintained and operated.,','8089'),('2947','2947','0','Accurate thermometers (stem & hot/cold holding) provided and used.,','8090'),('2948','2948','0','Single use items not reused or misused.,','8091'),('2949','2949','0','Person in charge available and knowledgeable/management certification.,','8092'),('2950','2950','0','Backflow prevention devices and methods in place and maintained.,','8093'),('2951','2951','0','Food and warewashing equipment approved,properly designed,constructed and installed.,','8094'),('2952','2952','0','PHF/TCSs properly thawed. Fruits and vegetables washed prior to preparation of service.,','8095'),('2953','2953','0','Grade card/signs posted. Consumer advisory. Records/logs. NCIAA. PHFs labeled/dated. Offsite label.,','8096'),('2954','2954','5','Time as a control. Operational plan,waiver/variance followed. Permit parameters followed.,,','8097'),('2955','2955','3','Kitchenware & FCS of equip. properly washed,rinsed,san. & air dried. San solution as required.,','8098'),('2956','2956','3','Person in charge available and knowledgeable/management certification,','8099'),('3046','3046','5','Approved water source with required documentation.,','8100'),('3047','3047','5','Required E-Coli lab testing documented. (NAC 445A.555 a),','8101'),('3048','3048','5','Required Annual & 4-year series lab testing documented. (NAC 445A. 555 b&c),','8102'),('3049','3049','3','Container testing conducted every three months. (NAC 445A.563),','8103'),('3050','3050','3','Pre and Post Water testing conducted as required. ( NAC445A.557),','8104'),('3064','3064','3','Proper labeling of food for consumption off site and/or transportation.,','8105'),('3065','3065','3','Person in charge available and knowledgeable/management certification.Facility has an effective employee health policy.,','8106'),('3066','3066','3','Grade card and required signs posted conspicuously. Records/logs maintained and available when required. NCIAA compliant.,','8107'),('3067','3067','0','Appropriate sanitizer test kits provided and used. Ware washing thermometer(s) are required. Wiping cloths and linens stored and used properly. Permanently affixed thermometers.,','8108'),('3068','3068','0','Facility in sound condition and maintained (floors,walls,ceilings,plumbing,lighting,ventilation,etc.)','8109'),('3069','3069','5','Operational plan,HACCP plan,waiver or variance approved and followed when required. Operating within the parameters of the health permit.,','8110'),('4177','4177','0','Dumpsters lids open,','8111'),('4178','4178','0','Dumpsters located less than 50 ft from doors,','8112'),('4179','4179','0','Dumpster on soil or damaged pavement,','8113'),('4180','4180','0','Trash spillage around dumpsters,','8114'),('4181','4181','0','Outdoor trash cans with no lids,','8115'),('4182','4182','0','Weatherstripping and/or door sweeps in disrepair,','8116'),('4183','4183','0','Windows damaged and/or screens missing,','8117'),('4184','4184','0','Penetrations not sealed,','8118'),('4185','4185','0','Walls/roof line in disrepair,','8119'),('4186','4186','0','Ventilation intakes not screened,','8120'),('4187','4187','0','Water not adequately draining,','8121'),('4188','4188','0','Roof in disrepair,','8122'),('4189','4189','0','Gutters clogged,','8123'),('4190','4190','0','Other,','8124'),('4191','4191','0','Overgrown/Excessive vegetation,','8125'),('4192','4192','0','Trees/Vegetation in contact with building,','8126'),('4193','4193','0','Tree hazard observed,','8127'),('4194','4194','0','Overgrown/Excessive vegetation,','8128'),('4195','4195','0','Evidence of rodents,','8129'),('4196','4196','0','Evidence of nuisance birds,','8130'),('4197','4197','0','Other,','8131'),('4198','4198','0','General unsanitary conditions observed,','8132'),('4199','4199','0','General unsanitary conditions observed,','8133'),('4200','4200','0','General unsanitary conditions observed,','8134'),('4201','4201','0','General unsanitary conditions observed,','8135'),('4202','4202','0','Other,','8136'),('4203','4203','0','Evidence of rodents,','8137'),('4204','4204','0','Evidence of flies,','8138'),('4205','4205','0','Evidence of cockroaches,','8139'),('4206','4206','0','Other,','8140'),('4207','4207','0','Administrative procedures not followed as required,','8141'),('4208','4208','0','Sticky traps not serviced as needed,','8142'),('4209','4209','0','Light traps not serviced as needed,','8143'),('4210','4210','0','Bait stations not serviced as needed,','8144'),('4771','4771','0','Interruption of electrical service,','8145'),('4772','4772','0','No potable water or hot water,','8146'),('4773','4773','0','Gross unsanitary occurrences or conditions including pest infestation,','8147'),('4774','4774','0','Sewage or liquid waste not disposed of in an approved manner,','8148'),('4775','4775','0','Lack of adequate refrigeration,','8149'),('4776','4776','0','Lack of adequate employee toilets and handwashing facilities,','8150'),('4777','4777','0','Suspected foodborne illness outbreak,','8151'),('4778','4778','0','Other condition or circumstance that may endanger public health,','8152'),('4779','4779','5','Operating within the parameters of the health permit. Compliance with Time as a Public Health Control,waiver,specialized process,and Hazard Analysis Critical Control Point (HACCP) plan.,,','8153'),('4780','4780','5','Handwashing (as required,when required,proper glove use,no bare hand contact of ready to eat foods). Food handler health restrictions as required.,,','8154'),('4781','4781','5','Commercially manufactured food from approved source with required labels. Parasite destruction as required. Time temperature control for safety (TCS) food received at proper temperature.,','8155'),('4782','4782','5','Hot and cold running water from approved source as required.,','8156'),('4783','4783','5','No imminently dangerous cross connection,adequate backflow prevention. Wastewater and sewage properly disposed.,,','8157'),('4784','4784','5','Food wholesome,not spoiled,contaminated,or adulterated.,,','8158'),('4785','4785','5','TCS food cooked and reheated to proper temperatures.,','8159'),('4786','4786','5','TCS food properly cooled.,','8160'),('4787','4787','5','TCS food at proper temperatures.,','8161'),('4788','4788','3','Equipment approved,properly designed,maintained,and operated.,,','8162'),('4789','4789','3','Food protected from potential cross-contamination.,','8163'),('4790','4790','3','Chemicals properly identified,stored,and used.,','8164'),('4791','4791','3','Food protected from potential contamination by employees and consumers.,','8165'),('4792','4792','3','Food contact surfaces of equipment properly cleaned and sanitized. Sanitizer solution provided and maintained as required.,','8166'),('4793','4793','3','Adequate handwashing sinks stocked and accessible.,','8167'),('4794','4794','3','Effective pest control measures. Animals restricted as required.,','8168'),('4795','4795','3','Grade card posted conspicuously. Consumer advisory as required.,','8169'),('4796','4796','3','Thermometers provided and accurate.,','8170'),('4797','4797','3','TCS food thawed and cooled using proper methods. Fruits and vegetables washed prior to preparation or service.,','8171'),('4798','4798','3','Single-use/single-service items properly used.,','8172'),('4799','4799','3','Person in charge present,demonstrates knowledge,and performs duties. Effective employee health policy. Mandated certification and food handler card as required.,','8173'),('4800','4800','3','Proper backflow prevention devices in place and maintained.,','8174'),('4801','4801','3','TCS food labeled and dated as required. Food sold for offsite consumption labeled properly. Records,logs,policies,and procedures maintained and available when required.,,','8175'),('4802','4802','0','Personal cleanliness maintained. Personal effects properly stored.,','8176'),('4803','4803','0','Non-TCS food labeled and within shelf-life. Food stored off the floor. Proper retail storage of chemicals.,','8177'),('4804','4804','0','Ware washing facilities maintained. Wiping cloths properly stored,test strips available.,,','8178'),('4805','4805','0','Signs and certifications as required.,','8179'),('4806','4806','0','Small wares approved,properly designed,in good repair.,','8180'),('4807','4807','0','Utensils,equipment,linens,single-service/single-use items properly handled,stored,and dispensed.,','8181'),('4808','4808','0','Nonfood contact surfaces and equipment properly constructed,installed,maintained,and clean.,,','8182'),('4809','4809','0','Restrooms custodial areas,and premises maintained.,','8183'),('4810','4810','0','Physical facility in sound condition and maintained.,','8184');

============================== d80bfe6a-8f2d-4e56-8640-b7fc32cf545b ==============================
-- created_at: 2026-03-20T16:55:47.427031323+00:00
-- finished_at: 2026-03-20T16:55:47.564099433+00:00
-- elapsed: 137ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c32877-0308-2621-0023-c5530002cf12
-- desc: execute adapter call
show terse schemas in database PC_DBT_DB
    limit 10000
/* {"app": "dbt", "connection_name": "", "dbt_version": "2.0.0", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:55:48.052363368+00:00
-- finished_at: 2026-03-20T16:55:48.316622116+00:00
-- elapsed: 264ms
-- outcome: success
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: 01c32877-0308-2467-0023-c55300026e92
-- desc: get_relation > list_relations call
SHOW OBJECTS IN SCHEMA "PC_DBT_DB"."DBT_EAPPEL" LIMIT 10000;
-- created_at: 2026-03-20T16:55:48.319441839+00:00
-- finished_at: 2026-03-20T16:55:48.529742017+00:00
-- elapsed: 210ms
-- outcome: success
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: 01c32877-0308-29eb-0023-c5530004129a
-- desc: execute adapter call
begin
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "seed.elvis.violation_codes", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:55:48.529943061+00:00
-- finished_at: 2026-03-20T16:55:48.805157932+00:00
-- elapsed: 275ms
-- outcome: success
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: 01c32877-0308-24a8-0023-c5530002dcba
-- desc: execute adapter call

    
    truncate table "PC_DBT_DB"."DBT_EAPPEL"."VIOLATION_CODES"
  
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "seed.elvis.violation_codes", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:55:48.805383419+00:00
-- finished_at: 2026-03-20T16:55:49.185273807+00:00
-- elapsed: 379ms
-- outcome: success
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: 01c32877-0308-29ec-0023-c553000451b6
-- desc: execute adapter call

    commit
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "seed.elvis.violation_codes", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:55:49.188252525+00:00
-- finished_at: 2026-03-20T16:55:49.460975503+00:00
-- elapsed: 272ms
-- outcome: success
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: 01c32877-0308-29eb-0023-c5530004129e
-- desc: add_query adapter call
BEGIN;
-- created_at: 2026-03-20T16:55:49.463137319+00:00
-- finished_at: 2026-03-20T16:55:50.172246078+00:00
-- elapsed: 709ms
-- outcome: error
-- error vendor code: 100038
-- error message: Internal: [Snowflake] 100038 (22018): DML operation to table PC_DBT_DB.DBT_EAPPEL.VIOLATION_CODES failed on column VIOLATION_CODE with error: Numeric value '1-Jun' is not recognized
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: not available
-- desc: add_query adapter call
insert into PC_DBT_DB.dbt_EAppel.violation_codes (VIOLATION_ID, VIOLATION_CODE, VIOLATION_DEMERITS, VIOLATION_DESCRIPTION, OBJECTID) values
            ('1','1','6','Food not obtained from approved sources and/or improperly identified.','7972'),('2','2','6','Food spoiled or adulterated.','7973'),('3','3','6','Employee(s) working with boils,infected wounds,respiratory,infections and/or other communicable diseases.,','7974'),('4','4','4','Inadequate hot and cold holding equipment,improperly designed,maintained and/or operated.,','7975'),('5','5','10','Hot potentially hazardous foods not rapidly cooled by approved methods.,,','7976'),('7','7','2','Potentially hazardous foods improperly thawed.,','7977'),('8','8','3','Potentially hazardous salads and/or fillings not made with prechilled ingredients.,','7978'),('9','9','2','Perishable foods kept at improper temperature.,','7979'),('10','10','3','Suitable thermometers (stem,cooler,oven) not provided and/or inadequately used.,','7980'),('12','12','6','Food workers improperly washing hands after using toilet,coughing,eating,smoking,after handling raw animal products and/or otherwise contaminating their hands.Inadequatefacilities.,','7981'),('13','13','3','Unsuitable hand washing facilities,unclean,inaccessible and/or not in good repair,with unapproved soap,towels and/or waste receptacles not provided.,','7982'),('14','14','4','Kitchenware and/or food contact surfaces of equipment improperly cleaned,sanitized and/or air dried.,,','7983'),('15','15','6','Sewage not disposed into public sewer or approved facility. Cross-connections or back siphonage present.,','7984'),('16','16','6','No hot and cold running water as required and/or water not from an approved source.,','7985'),('17','17','2','Fruits and vegetables improperly washed prior to serving.,','7986'),('18','18','1','Foods not stored off the floor.,','7987'),('19','19','1','Required labels not present on food or containers of food.Required signs not posted.,','7988'),('20','20','1','Health cards not current on all food handlers.,','7989'),('21','21','1','Unacceptable hygienic practices,unclean outer garments,improper hair restraints used.,','7990'),('22','22','1','In-use utensils improperly handled and/or stored.,','7991'),('23','23','1','Facilities for washing and sanitizing equipment and utensils unapproved,inadequate,improperly constructed,maintained and/or operated.,,','7992'),('24','24','1','Accurate thermometers,chemical tests kits,and/or pressure gauges not present and/or working.,','7993'),('25','25','1','Clean utensils,equipment and/or singe service items improperly handled,stored and/or dispensed.,','7994'),('26','26','3','Single service items reused.,','7995'),('27','27','1','Unclean wiping cloths,stored in an unapproved sanitizer,and/or unrestricted in use.,','7996'),('28','28','1','Unapproved food contact surfaces. Food contact surfaces notsmooth,easily cleanable,properly constructed and/or installed.,','7997'),('29','29','1','Plastic used for food contact surfaces is not of approved food grade quality.,','7998'),('30','30','1','Non-food contact surfaces improperly constructed and/or installed.,','7999'),('31','31','1','Non-food contact surfaces and/or cooking devices not maintained and/or unclean.,','8000'),('32','32','1','Toilet facilities for employees inadequate,inconvenient,unclean and/or not in good repair.Covered trash cans not provided.Doors not self-closing.,','8001'),('33','33','1','Garbage storage and/or removal inadequate and/or unclean.Garbage containers not clean,pest proof,non-absorbent and covered.Wash area unclean and/or not maintained.,','8002'),('34','34','3','No effective measures to control pests.Pest control devices not maintained.,','8003'),('35','35','1','Improper lighting and/or ventilation,ventilation hoods and/or filters improperly cleaned and/or maintained.,,','8004'),('36','36','1','Plumbing and/or fixtures improperly sized,installed and/or maintained. Plumbing and/or fixtures improperly drained.,,','8005'),('37','37','1','Floors,walls,ceilings,improperly constructed and/or installed.Not in good repair and/or clean.,,','8006'),('38','38','1','Living quarters not completely separated from food service.Infant or child care allowed.Premises not maintained free of litter,unnecessary equipment and/or personal effects.,,','8007'),('39','39','1','Live animals not in compliance with current Regulations.,','8008'),('40','40','1','Non-compliant with Nevada Revised Statute 202.2483 regarding smoking.,','8009'),('61','1-Jun','6','Poultry,poultry stuffing,stuffed meats,stuffing containing meats,casseroles containing potentially hazardous foods and/or food to be reheated containing potentially hazardous food not cooked to an internal temperature of 165°F.,','8010'),('62','2-Jun','6','Ground,fabricated and/or restructured meats not cooked throughout to 155&deg,F.,','8011'),('63','3-Jun','6','Pork and/or any food containing pork,not cooked to an internal temperature of 155&deg,F or above.,','8012'),('64','4-Jun','6','Potentially hazardous foods not kept at 40&deg,F or colder or at 140&deg,F or hotter,except during necessary preparation procedures.,,','8013'),('111','1-Nov','4','Food unprotected from cross-contamination by raw meats,poultry,fish,seafood and/or raw eggs.,,','8014'),('112','2-Nov','4','Food unprotected from cross-contamination by food handlers.,','8015'),('113','3-Nov','4','Food unprotected from cross-contamination by chemicals.,','8016'),('114','4-Nov','4','Food unprotected by cross-contamination by proper storage.,','8017'),('201','1','5','Verifiable time as a control with approved procedure when in use. Operational plan,HACCP plan,waiver or variance approved and followed when required. Nevada Clean Indoor Air Act compliant.,','8018'),('202','2','5','Handwashing (as required,when required,proper glove use,no bare hand contact of ready to eat foods).Foodhandler health restrictions as required.,,','8019'),('203','3','5','Commercially manufactured food from approved source with required labels. Parasite destruction as required. Potentially hazardous foods/time temperature control for safety (PHF/TCS) received at proper temperature.,','8020'),('204','4','5','Hot and cold running water from approved source as required.,','8021'),('205','5','5','Imminently dangerous cross connection or backflow.Waste water and sewage disposed into public sewer or approved facility.,','8022'),('206','6','5','Food wholesome,not spoiled,contaminated,or adulterated.,,','8023'),('207','7','5','PHF/TCSs cooked and reheated to proper temperatures.,','8024'),('208','8','5','PHF/TCSs properly cooled.,','8025'),('209','9','5','PHF/TCSs at proper temperatures during storage,display,service,transport,and holding. ,','8026'),('210','10','5','Operating within the parameters of the health permit.,','8027'),('211','11','3','Food protected from potential contamination during storage and preparation.,','8028'),('212','12','3','Food protected from potential contamination by chemicals. Toxic items properly labeled,stored and used.,,','8029'),('213','13','3','Food protected from potential contamination by employees and consumers.,','8030'),('214','14','3','Kitchenware and food contact surfaces of equipment properly washed,rinsed,sanitized and air dried.Sanitizer solution provided and maintained as required.,','8031'),('215','15','3','Handwashing facilities adequate in number,stocked,accessible,and limited to handwashing only.,,','8032'),('216','16','3','Effective pest control measures. Animals restricted as required.,','8033'),('217','17','3','Hot and cold holding equipment present,properly designed,maintained and operated.,','8034'),('218','18','3','Accurate thermometers (stem & hot/cold holding) provided and used.,','8035'),('219','19','3','PHF/TCSs properly thawed.,','8036'),('220','20','3','Single use items not reused or misused.,','8037'),('221','21','3','Person in charge available and knowledgeable/management certification.,','8038'),('222','22','3','Backflow prevention devices and methods in place and maintained.,','8039'),('223','23','3','B or C" grade card and required signs posted conspicuously. Consumer advisory as required. Records/logs maintained and available when required.,"','8040'),('224','24','1','Acceptable personal hygiene practices,clean outer garments,proper hair restraints used. Living quarters and child care completely separated from food service.,','8041'),('225','25','1','Food and food storage containers properly labeled and dated as required. Food stored off the floor when required. Non-PHF/TCS not spoiled and within shelf-life. Proper retail storage of chemicals.,','8042'),('226','26','1','Facilities for washing and sanitizing kitchenware approved,adequate,properly constructed,maintained and operated. ,,','8043'),('227','27','1','Appropriate sanitizer test kits provided and used. Ware washing thermometer(s) as required. Wiping cloths & linens stored and used properly.,','8044'),('228','28','1','Food contact surfaces and equipment approved,food grade material,smooth,easily cleanable,properly constructed and installed.,','8045'),('229','29','1','Utensils,equipment,and single serve items properly handled,stored,and dispensed.,','8046'),('230','30','1','Nonfood contact surfaces and equipment properly constructed,installed,maintained and clean.,','8047'),('231','31','1','Health cards as required. Foodhandler not aware of employee health policy. A" grade card posted conspicuously. ,"','8048'),('232','32','1','Restrooms,mop sink,and custodial areas maintained and clean.Premises maintained free of litter,unnecessary equipment,or personal effects. Trash areas adequate,pest proof,and clean.','8049'),('233','33','1','Facility in sound condition and maintained (floors,walls,ceilings,plumbing,lighting,ventilation,etc.).','8050'),('234','34','1','Fruits and vegetables washed prior to preparation or service.,','8051'),('301','IHH-1','0','Imminent Health Hazard - (Immediate Closure) - Interruption of electrical service,','8052'),('302','IHH-2','0','Imminent Health Hazard - (Immediate Closure) - No potable water or hot water,','8053'),('303','IHH-3','0','Imminent Health Hazard - (Immediate Closure) - Gross unsanitary occurrences or conditions including pest infestation,','8054'),('304','IHH-4','0','Imminent Health Hazard - (Immediate Closure) - Sewage or liquid waste not disposed of in an approved manner,','8055'),('305','IHH-5','0','Imminent Health Hazard - (Immediate Closure) - Lack of adequate refrigeration,','8056'),('306','IHH-6','0','Imminent Health Hazard - (Immediate Closure) - Lack of adequate employee toilets and handwashing facilities,','8057'),('307','IHH-7','0','Imminent Health Hazard - (Immediate Closure) - Misuse of poisonous or toxic materials,','8058'),('308','IHH-8','0','Imminent Health Hazard - (Immediate Closure) - Suspected foodborne illness outbreak,','8059'),('309','IHH-9','0','Imminent Health Hazard - (Immediate Closure) - Emergency such as fire and/or flood,','8060'),('310','IHH-10','0','Imminent Health Hazard - (Immediate Closure) - Other condition or circumstance that may endanger public health,','8061'),('2907','2907','3','Food and warewashing equipment approved,properly designed,constructed and installed.,','8062'),('2908','2908','3','PHF/TCSs properly thawed. Fruits and vegetables washed prior to preparation or service.,','8063'),('2909','2909','3','Grade/card signs posted. Consumer advisory. Records/logs. NCIAA. PHFs labeled/dated. Offsite label.,','8064'),('2910','2910','0','Non-PHF labeled/dated/not spoiled/within shelf-life. Food stored off-floor. Retail chemical storage.,','8065'),('2911','2911','0','Sanitizer kits available. Equip. & ware washing therm. as required. Wiping cloths and linen use.,','8066'),('2912','2912','0','Small wares and portable appliances approved,properly designed,in good repair.,','8067'),('2925','2925','0','Acceptable personal hygiene,clean garments,hair restraints. Living quarters & child care separate.,','8068'),('2926','2926','0','Ware washing facilities approved,adequate,properly constructed,maintained & operated.,,','8069'),('2927','2927','0','Utensils,equipment,and single serve items properly handled,stored,and dispensed.,','8070'),('2928','2928','0','Nonfood contact surfaces and equipment properly constructed,installed,maintained and clean.,','8071'),('2929','2929','0','RR''s,mop sk,cust. areasclean/maint. No litter,unnec. equip,pers items. Trash area clean/maint.,','8072'),('2930','2930','0','Facility maintained (floors,walls,ceilings,plumbing,lighting,ventilation,etc.).','8073'),('2931','2931','0','Time as a control. Operational plan,waiver/variance followed. Permit parameters followed.,,','8074'),('2932','2932','0','Hand washing as required,no bare hand w/ RTE foods. Foodhandler health restrictions as required.,,','8075'),('2933','2933','0','Food from an approved source w/ proper labels. Parasite destruction. PHF''s received @ proper temp.,','8076'),('2934','2934','0','Hot & cold running water from an approved source as required.,','8077'),('2935','2935','0','Imminently dangerous cross connection or backflow. Waste water and sewage properly disposed of.,','8078'),('2936','2936','0','Food wholesome,not spoiled,contaminated,or adulterated.,,','8079'),('2937','2937','0','PHF/TCSs cooked and reheated to proper temperature.,','8080'),('2938','2938','0','PHF/TCSs properly cooled.,','8081'),('2939','2939','0','PHF/TCSs maintained at proper temperature.,','8082'),('2940','2940','0','Food protected from potential contamination during storage and preparation.,','8083'),('2941','2941','0','Food protected from potential contamination by chemicals. Toxic items labeled,stored & used.,,','8084'),('2942','2942','0','Food protected from potential contamination by employees and consumers.,','8085'),('2943','2943','0','Kitchenware & FCS of equip. properly washed,rinsed,san. & air dried. San solution as required.,','8086'),('2944','2944','0','Handwashing facilities adequate in number,stocked,accessible,and limited to handwashing only.,,','8087'),('2945','2945','0','Effective pest control measures. Animals restricted as required.,','8088'),('2946','2946','0','Hot and cold holding equipment present,properly designed,maintained and operated.,','8089'),('2947','2947','0','Accurate thermometers (stem & hot/cold holding) provided and used.,','8090'),('2948','2948','0','Single use items not reused or misused.,','8091'),('2949','2949','0','Person in charge available and knowledgeable/management certification.,','8092'),('2950','2950','0','Backflow prevention devices and methods in place and maintained.,','8093'),('2951','2951','0','Food and warewashing equipment approved,properly designed,constructed and installed.,','8094'),('2952','2952','0','PHF/TCSs properly thawed. Fruits and vegetables washed prior to preparation of service.,','8095'),('2953','2953','0','Grade card/signs posted. Consumer advisory. Records/logs. NCIAA. PHFs labeled/dated. Offsite label.,','8096'),('2954','2954','5','Time as a control. Operational plan,waiver/variance followed. Permit parameters followed.,,','8097'),('2955','2955','3','Kitchenware & FCS of equip. properly washed,rinsed,san. & air dried. San solution as required.,','8098'),('2956','2956','3','Person in charge available and knowledgeable/management certification,','8099'),('3046','3046','5','Approved water source with required documentation.,','8100'),('3047','3047','5','Required E-Coli lab testing documented. (NAC 445A.555 a),','8101'),('3048','3048','5','Required Annual & 4-year series lab testing documented. (NAC 445A. 555 b&c),','8102'),('3049','3049','3','Container testing conducted every three months. (NAC 445A.563),','8103'),('3050','3050','3','Pre and Post Water testing conducted as required. ( NAC445A.557),','8104'),('3064','3064','3','Proper labeling of food for consumption off site and/or transportation.,','8105'),('3065','3065','3','Person in charge available and knowledgeable/management certification.Facility has an effective employee health policy.,','8106'),('3066','3066','3','Grade card and required signs posted conspicuously. Records/logs maintained and available when required. NCIAA compliant.,','8107'),('3067','3067','0','Appropriate sanitizer test kits provided and used. Ware washing thermometer(s) are required. Wiping cloths and linens stored and used properly. Permanently affixed thermometers.,','8108'),('3068','3068','0','Facility in sound condition and maintained (floors,walls,ceilings,plumbing,lighting,ventilation,etc.)','8109'),('3069','3069','5','Operational plan,HACCP plan,waiver or variance approved and followed when required. Operating within the parameters of the health permit.,','8110'),('4177','4177','0','Dumpsters lids open,','8111'),('4178','4178','0','Dumpsters located less than 50 ft from doors,','8112'),('4179','4179','0','Dumpster on soil or damaged pavement,','8113'),('4180','4180','0','Trash spillage around dumpsters,','8114'),('4181','4181','0','Outdoor trash cans with no lids,','8115'),('4182','4182','0','Weatherstripping and/or door sweeps in disrepair,','8116'),('4183','4183','0','Windows damaged and/or screens missing,','8117'),('4184','4184','0','Penetrations not sealed,','8118'),('4185','4185','0','Walls/roof line in disrepair,','8119'),('4186','4186','0','Ventilation intakes not screened,','8120'),('4187','4187','0','Water not adequately draining,','8121'),('4188','4188','0','Roof in disrepair,','8122'),('4189','4189','0','Gutters clogged,','8123'),('4190','4190','0','Other,','8124'),('4191','4191','0','Overgrown/Excessive vegetation,','8125'),('4192','4192','0','Trees/Vegetation in contact with building,','8126'),('4193','4193','0','Tree hazard observed,','8127'),('4194','4194','0','Overgrown/Excessive vegetation,','8128'),('4195','4195','0','Evidence of rodents,','8129'),('4196','4196','0','Evidence of nuisance birds,','8130'),('4197','4197','0','Other,','8131'),('4198','4198','0','General unsanitary conditions observed,','8132'),('4199','4199','0','General unsanitary conditions observed,','8133'),('4200','4200','0','General unsanitary conditions observed,','8134'),('4201','4201','0','General unsanitary conditions observed,','8135'),('4202','4202','0','Other,','8136'),('4203','4203','0','Evidence of rodents,','8137'),('4204','4204','0','Evidence of flies,','8138'),('4205','4205','0','Evidence of cockroaches,','8139'),('4206','4206','0','Other,','8140'),('4207','4207','0','Administrative procedures not followed as required,','8141'),('4208','4208','0','Sticky traps not serviced as needed,','8142'),('4209','4209','0','Light traps not serviced as needed,','8143'),('4210','4210','0','Bait stations not serviced as needed,','8144'),('4771','4771','0','Interruption of electrical service,','8145'),('4772','4772','0','No potable water or hot water,','8146'),('4773','4773','0','Gross unsanitary occurrences or conditions including pest infestation,','8147'),('4774','4774','0','Sewage or liquid waste not disposed of in an approved manner,','8148'),('4775','4775','0','Lack of adequate refrigeration,','8149'),('4776','4776','0','Lack of adequate employee toilets and handwashing facilities,','8150'),('4777','4777','0','Suspected foodborne illness outbreak,','8151'),('4778','4778','0','Other condition or circumstance that may endanger public health,','8152'),('4779','4779','5','Operating within the parameters of the health permit. Compliance with Time as a Public Health Control,waiver,specialized process,and Hazard Analysis Critical Control Point (HACCP) plan.,,','8153'),('4780','4780','5','Handwashing (as required,when required,proper glove use,no bare hand contact of ready to eat foods). Food handler health restrictions as required.,,','8154'),('4781','4781','5','Commercially manufactured food from approved source with required labels. Parasite destruction as required. Time temperature control for safety (TCS) food received at proper temperature.,','8155'),('4782','4782','5','Hot and cold running water from approved source as required.,','8156'),('4783','4783','5','No imminently dangerous cross connection,adequate backflow prevention. Wastewater and sewage properly disposed.,,','8157'),('4784','4784','5','Food wholesome,not spoiled,contaminated,or adulterated.,,','8158'),('4785','4785','5','TCS food cooked and reheated to proper temperatures.,','8159'),('4786','4786','5','TCS food properly cooled.,','8160'),('4787','4787','5','TCS food at proper temperatures.,','8161'),('4788','4788','3','Equipment approved,properly designed,maintained,and operated.,,','8162'),('4789','4789','3','Food protected from potential cross-contamination.,','8163'),('4790','4790','3','Chemicals properly identified,stored,and used.,','8164'),('4791','4791','3','Food protected from potential contamination by employees and consumers.,','8165'),('4792','4792','3','Food contact surfaces of equipment properly cleaned and sanitized. Sanitizer solution provided and maintained as required.,','8166'),('4793','4793','3','Adequate handwashing sinks stocked and accessible.,','8167'),('4794','4794','3','Effective pest control measures. Animals restricted as required.,','8168'),('4795','4795','3','Grade card posted conspicuously. Consumer advisory as required.,','8169'),('4796','4796','3','Thermometers provided and accurate.,','8170'),('4797','4797','3','TCS food thawed and cooled using proper methods. Fruits and vegetables washed prior to preparation or service.,','8171'),('4798','4798','3','Single-use/single-service items properly used.,','8172'),('4799','4799','3','Person in charge present,demonstrates knowledge,and performs duties. Effective employee health policy. Mandated certification and food handler card as required.,','8173'),('4800','4800','3','Proper backflow prevention devices in place and maintained.,','8174'),('4801','4801','3','TCS food labeled and dated as required. Food sold for offsite consumption labeled properly. Records,logs,policies,and procedures maintained and available when required.,,','8175'),('4802','4802','0','Personal cleanliness maintained. Personal effects properly stored.,','8176'),('4803','4803','0','Non-TCS food labeled and within shelf-life. Food stored off the floor. Proper retail storage of chemicals.,','8177'),('4804','4804','0','Ware washing facilities maintained. Wiping cloths properly stored,test strips available.,,','8178'),('4805','4805','0','Signs and certifications as required.,','8179'),('4806','4806','0','Small wares approved,properly designed,in good repair.,','8180'),('4807','4807','0','Utensils,equipment,linens,single-service/single-use items properly handled,stored,and dispensed.,','8181'),('4808','4808','0','Nonfood contact surfaces and equipment properly constructed,installed,maintained,and clean.,,','8182'),('4809','4809','0','Restrooms custodial areas,and premises maintained.,','8183'),('4810','4810','0','Physical facility in sound condition and maintained.,','8184');

============================== c6fd0c05-5937-46ac-ad83-47e6df2e19d9 ==============================
-- created_at: 2026-03-20T16:56:04.246545730+00:00
-- finished_at: 2026-03-20T16:56:04.522308442+00:00
-- elapsed: 275ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c32878-0308-28d7-0023-c5530002fbce
-- desc: execute adapter call
show terse schemas in database PC_DBT_DB
    limit 10000
/* {"app": "dbt", "connection_name": "", "dbt_version": "2.0.0", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:56:04.530393498+00:00
-- finished_at: 2026-03-20T16:56:04.726220205+00:00
-- elapsed: 195ms
-- outcome: success
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: 01c32878-0308-2a04-0023-c553000441ca
-- desc: get_relation > list_relations call
SHOW OBJECTS IN SCHEMA "PC_DBT_DB"."DBT_EAPPEL" LIMIT 10000;
-- created_at: 2026-03-20T16:56:04.728499696+00:00
-- finished_at: 2026-03-20T16:56:04.971058431+00:00
-- elapsed: 242ms
-- outcome: success
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: 01c32878-0308-26c9-0023-c5530003f2c6
-- desc: execute adapter call
begin
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "seed.elvis.violation_codes", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:56:04.971283275+00:00
-- finished_at: 2026-03-20T16:56:05.215730544+00:00
-- elapsed: 244ms
-- outcome: success
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: 01c32878-0308-28d8-0023-c5530003e39e
-- desc: execute adapter call

    
    truncate table "PC_DBT_DB"."DBT_EAPPEL"."VIOLATION_CODES"
  
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "seed.elvis.violation_codes", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:56:05.215949700+00:00
-- finished_at: 2026-03-20T16:56:05.756357079+00:00
-- elapsed: 540ms
-- outcome: success
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: 01c32878-0308-2a04-0023-c553000441ce
-- desc: execute adapter call

    commit
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "seed.elvis.violation_codes", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:56:05.759253739+00:00
-- finished_at: 2026-03-20T16:56:05.978687131+00:00
-- elapsed: 219ms
-- outcome: success
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: 01c32878-0308-26c9-0023-c5530003f2ca
-- desc: add_query adapter call
BEGIN;
-- created_at: 2026-03-20T16:56:05.981107652+00:00
-- finished_at: 2026-03-20T16:56:06.681438479+00:00
-- elapsed: 700ms
-- outcome: error
-- error vendor code: 100038
-- error message: Internal: [Snowflake] 100038 (22018): DML operation to table PC_DBT_DB.DBT_EAPPEL.VIOLATION_CODES failed on column VIOLATION_CODE with error: Numeric value '1-Jun' is not recognized
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: not available
-- desc: add_query adapter call
insert into PC_DBT_DB.dbt_EAppel.violation_codes (VIOLATION_ID, VIOLATION_CODE, VIOLATION_DEMERITS, VIOLATION_DESCRIPTION, OBJECTID) values
            ('1','1','6','Food not obtained from approved sources and/or improperly identified.','7972'),('2','2','6','Food spoiled or adulterated.','7973'),('3','3','6','Employee(s) working with boils,infected wounds,respiratory,infections and/or other communicable diseases.,','7974'),('4','4','4','Inadequate hot and cold holding equipment,improperly designed,maintained and/or operated.,','7975'),('5','5','10','Hot potentially hazardous foods not rapidly cooled by approved methods.,,','7976'),('7','7','2','Potentially hazardous foods improperly thawed.,','7977'),('8','8','3','Potentially hazardous salads and/or fillings not made with prechilled ingredients.,','7978'),('9','9','2','Perishable foods kept at improper temperature.,','7979'),('10','10','3','Suitable thermometers (stem,cooler,oven) not provided and/or inadequately used.,','7980'),('12','12','6','Food workers improperly washing hands after using toilet,coughing,eating,smoking,after handling raw animal products and/or otherwise contaminating their hands.Inadequatefacilities.,','7981'),('13','13','3','Unsuitable hand washing facilities,unclean,inaccessible and/or not in good repair,with unapproved soap,towels and/or waste receptacles not provided.,','7982'),('14','14','4','Kitchenware and/or food contact surfaces of equipment improperly cleaned,sanitized and/or air dried.,,','7983'),('15','15','6','Sewage not disposed into public sewer or approved facility. Cross-connections or back siphonage present.,','7984'),('16','16','6','No hot and cold running water as required and/or water not from an approved source.,','7985'),('17','17','2','Fruits and vegetables improperly washed prior to serving.,','7986'),('18','18','1','Foods not stored off the floor.,','7987'),('19','19','1','Required labels not present on food or containers of food.Required signs not posted.,','7988'),('20','20','1','Health cards not current on all food handlers.,','7989'),('21','21','1','Unacceptable hygienic practices,unclean outer garments,improper hair restraints used.,','7990'),('22','22','1','In-use utensils improperly handled and/or stored.,','7991'),('23','23','1','Facilities for washing and sanitizing equipment and utensils unapproved,inadequate,improperly constructed,maintained and/or operated.,,','7992'),('24','24','1','Accurate thermometers,chemical tests kits,and/or pressure gauges not present and/or working.,','7993'),('25','25','1','Clean utensils,equipment and/or singe service items improperly handled,stored and/or dispensed.,','7994'),('26','26','3','Single service items reused.,','7995'),('27','27','1','Unclean wiping cloths,stored in an unapproved sanitizer,and/or unrestricted in use.,','7996'),('28','28','1','Unapproved food contact surfaces. Food contact surfaces notsmooth,easily cleanable,properly constructed and/or installed.,','7997'),('29','29','1','Plastic used for food contact surfaces is not of approved food grade quality.,','7998'),('30','30','1','Non-food contact surfaces improperly constructed and/or installed.,','7999'),('31','31','1','Non-food contact surfaces and/or cooking devices not maintained and/or unclean.,','8000'),('32','32','1','Toilet facilities for employees inadequate,inconvenient,unclean and/or not in good repair.Covered trash cans not provided.Doors not self-closing.,','8001'),('33','33','1','Garbage storage and/or removal inadequate and/or unclean.Garbage containers not clean,pest proof,non-absorbent and covered.Wash area unclean and/or not maintained.,','8002'),('34','34','3','No effective measures to control pests.Pest control devices not maintained.,','8003'),('35','35','1','Improper lighting and/or ventilation,ventilation hoods and/or filters improperly cleaned and/or maintained.,,','8004'),('36','36','1','Plumbing and/or fixtures improperly sized,installed and/or maintained. Plumbing and/or fixtures improperly drained.,,','8005'),('37','37','1','Floors,walls,ceilings,improperly constructed and/or installed.Not in good repair and/or clean.,,','8006'),('38','38','1','Living quarters not completely separated from food service.Infant or child care allowed.Premises not maintained free of litter,unnecessary equipment and/or personal effects.,,','8007'),('39','39','1','Live animals not in compliance with current Regulations.,','8008'),('40','40','1','Non-compliant with Nevada Revised Statute 202.2483 regarding smoking.,','8009'),('61','1-Jun','6','Poultry,poultry stuffing,stuffed meats,stuffing containing meats,casseroles containing potentially hazardous foods and/or food to be reheated containing potentially hazardous food not cooked to an internal temperature of 165°F.,','8010'),('62','2-Jun','6','Ground,fabricated and/or restructured meats not cooked throughout to 155&deg,F.,','8011'),('63','3-Jun','6','Pork and/or any food containing pork,not cooked to an internal temperature of 155&deg,F or above.,','8012'),('64','4-Jun','6','Potentially hazardous foods not kept at 40&deg,F or colder or at 140&deg,F or hotter,except during necessary preparation procedures.,,','8013'),('111','1-Nov','4','Food unprotected from cross-contamination by raw meats,poultry,fish,seafood and/or raw eggs.,,','8014'),('112','2-Nov','4','Food unprotected from cross-contamination by food handlers.,','8015'),('113','3-Nov','4','Food unprotected from cross-contamination by chemicals.,','8016'),('114','4-Nov','4','Food unprotected by cross-contamination by proper storage.,','8017'),('201','1','5','Verifiable time as a control with approved procedure when in use. Operational plan,HACCP plan,waiver or variance approved and followed when required. Nevada Clean Indoor Air Act compliant.,','8018'),('202','2','5','Handwashing (as required,when required,proper glove use,no bare hand contact of ready to eat foods).Foodhandler health restrictions as required.,,','8019'),('203','3','5','Commercially manufactured food from approved source with required labels. Parasite destruction as required. Potentially hazardous foods/time temperature control for safety (PHF/TCS) received at proper temperature.,','8020'),('204','4','5','Hot and cold running water from approved source as required.,','8021'),('205','5','5','Imminently dangerous cross connection or backflow.Waste water and sewage disposed into public sewer or approved facility.,','8022'),('206','6','5','Food wholesome,not spoiled,contaminated,or adulterated.,,','8023'),('207','7','5','PHF/TCSs cooked and reheated to proper temperatures.,','8024'),('208','8','5','PHF/TCSs properly cooled.,','8025'),('209','9','5','PHF/TCSs at proper temperatures during storage,display,service,transport,and holding. ,','8026'),('210','10','5','Operating within the parameters of the health permit.,','8027'),('211','11','3','Food protected from potential contamination during storage and preparation.,','8028'),('212','12','3','Food protected from potential contamination by chemicals. Toxic items properly labeled,stored and used.,,','8029'),('213','13','3','Food protected from potential contamination by employees and consumers.,','8030'),('214','14','3','Kitchenware and food contact surfaces of equipment properly washed,rinsed,sanitized and air dried.Sanitizer solution provided and maintained as required.,','8031'),('215','15','3','Handwashing facilities adequate in number,stocked,accessible,and limited to handwashing only.,,','8032'),('216','16','3','Effective pest control measures. Animals restricted as required.,','8033'),('217','17','3','Hot and cold holding equipment present,properly designed,maintained and operated.,','8034'),('218','18','3','Accurate thermometers (stem & hot/cold holding) provided and used.,','8035'),('219','19','3','PHF/TCSs properly thawed.,','8036'),('220','20','3','Single use items not reused or misused.,','8037'),('221','21','3','Person in charge available and knowledgeable/management certification.,','8038'),('222','22','3','Backflow prevention devices and methods in place and maintained.,','8039'),('223','23','3','B or C" grade card and required signs posted conspicuously. Consumer advisory as required. Records/logs maintained and available when required.,"','8040'),('224','24','1','Acceptable personal hygiene practices,clean outer garments,proper hair restraints used. Living quarters and child care completely separated from food service.,','8041'),('225','25','1','Food and food storage containers properly labeled and dated as required. Food stored off the floor when required. Non-PHF/TCS not spoiled and within shelf-life. Proper retail storage of chemicals.,','8042'),('226','26','1','Facilities for washing and sanitizing kitchenware approved,adequate,properly constructed,maintained and operated. ,,','8043'),('227','27','1','Appropriate sanitizer test kits provided and used. Ware washing thermometer(s) as required. Wiping cloths & linens stored and used properly.,','8044'),('228','28','1','Food contact surfaces and equipment approved,food grade material,smooth,easily cleanable,properly constructed and installed.,','8045'),('229','29','1','Utensils,equipment,and single serve items properly handled,stored,and dispensed.,','8046'),('230','30','1','Nonfood contact surfaces and equipment properly constructed,installed,maintained and clean.,','8047'),('231','31','1','Health cards as required. Foodhandler not aware of employee health policy. A" grade card posted conspicuously. ,"','8048'),('232','32','1','Restrooms,mop sink,and custodial areas maintained and clean.Premises maintained free of litter,unnecessary equipment,or personal effects. Trash areas adequate,pest proof,and clean.','8049'),('233','33','1','Facility in sound condition and maintained (floors,walls,ceilings,plumbing,lighting,ventilation,etc.).','8050'),('234','34','1','Fruits and vegetables washed prior to preparation or service.,','8051'),('301','IHH-1','0','Imminent Health Hazard - (Immediate Closure) - Interruption of electrical service,','8052'),('302','IHH-2','0','Imminent Health Hazard - (Immediate Closure) - No potable water or hot water,','8053'),('303','IHH-3','0','Imminent Health Hazard - (Immediate Closure) - Gross unsanitary occurrences or conditions including pest infestation,','8054'),('304','IHH-4','0','Imminent Health Hazard - (Immediate Closure) - Sewage or liquid waste not disposed of in an approved manner,','8055'),('305','IHH-5','0','Imminent Health Hazard - (Immediate Closure) - Lack of adequate refrigeration,','8056'),('306','IHH-6','0','Imminent Health Hazard - (Immediate Closure) - Lack of adequate employee toilets and handwashing facilities,','8057'),('307','IHH-7','0','Imminent Health Hazard - (Immediate Closure) - Misuse of poisonous or toxic materials,','8058'),('308','IHH-8','0','Imminent Health Hazard - (Immediate Closure) - Suspected foodborne illness outbreak,','8059'),('309','IHH-9','0','Imminent Health Hazard - (Immediate Closure) - Emergency such as fire and/or flood,','8060'),('310','IHH-10','0','Imminent Health Hazard - (Immediate Closure) - Other condition or circumstance that may endanger public health,','8061'),('2907','2907','3','Food and warewashing equipment approved,properly designed,constructed and installed.,','8062'),('2908','2908','3','PHF/TCSs properly thawed. Fruits and vegetables washed prior to preparation or service.,','8063'),('2909','2909','3','Grade/card signs posted. Consumer advisory. Records/logs. NCIAA. PHFs labeled/dated. Offsite label.,','8064'),('2910','2910','0','Non-PHF labeled/dated/not spoiled/within shelf-life. Food stored off-floor. Retail chemical storage.,','8065'),('2911','2911','0','Sanitizer kits available. Equip. & ware washing therm. as required. Wiping cloths and linen use.,','8066'),('2912','2912','0','Small wares and portable appliances approved,properly designed,in good repair.,','8067'),('2925','2925','0','Acceptable personal hygiene,clean garments,hair restraints. Living quarters & child care separate.,','8068'),('2926','2926','0','Ware washing facilities approved,adequate,properly constructed,maintained & operated.,,','8069'),('2927','2927','0','Utensils,equipment,and single serve items properly handled,stored,and dispensed.,','8070'),('2928','2928','0','Nonfood contact surfaces and equipment properly constructed,installed,maintained and clean.,','8071'),('2929','2929','0','RR''s,mop sk,cust. areasclean/maint. No litter,unnec. equip,pers items. Trash area clean/maint.,','8072'),('2930','2930','0','Facility maintained (floors,walls,ceilings,plumbing,lighting,ventilation,etc.).','8073'),('2931','2931','0','Time as a control. Operational plan,waiver/variance followed. Permit parameters followed.,,','8074'),('2932','2932','0','Hand washing as required,no bare hand w/ RTE foods. Foodhandler health restrictions as required.,,','8075'),('2933','2933','0','Food from an approved source w/ proper labels. Parasite destruction. PHF''s received @ proper temp.,','8076'),('2934','2934','0','Hot & cold running water from an approved source as required.,','8077'),('2935','2935','0','Imminently dangerous cross connection or backflow. Waste water and sewage properly disposed of.,','8078'),('2936','2936','0','Food wholesome,not spoiled,contaminated,or adulterated.,,','8079'),('2937','2937','0','PHF/TCSs cooked and reheated to proper temperature.,','8080'),('2938','2938','0','PHF/TCSs properly cooled.,','8081'),('2939','2939','0','PHF/TCSs maintained at proper temperature.,','8082'),('2940','2940','0','Food protected from potential contamination during storage and preparation.,','8083'),('2941','2941','0','Food protected from potential contamination by chemicals. Toxic items labeled,stored & used.,,','8084'),('2942','2942','0','Food protected from potential contamination by employees and consumers.,','8085'),('2943','2943','0','Kitchenware & FCS of equip. properly washed,rinsed,san. & air dried. San solution as required.,','8086'),('2944','2944','0','Handwashing facilities adequate in number,stocked,accessible,and limited to handwashing only.,,','8087'),('2945','2945','0','Effective pest control measures. Animals restricted as required.,','8088'),('2946','2946','0','Hot and cold holding equipment present,properly designed,maintained and operated.,','8089'),('2947','2947','0','Accurate thermometers (stem & hot/cold holding) provided and used.,','8090'),('2948','2948','0','Single use items not reused or misused.,','8091'),('2949','2949','0','Person in charge available and knowledgeable/management certification.,','8092'),('2950','2950','0','Backflow prevention devices and methods in place and maintained.,','8093'),('2951','2951','0','Food and warewashing equipment approved,properly designed,constructed and installed.,','8094'),('2952','2952','0','PHF/TCSs properly thawed. Fruits and vegetables washed prior to preparation of service.,','8095'),('2953','2953','0','Grade card/signs posted. Consumer advisory. Records/logs. NCIAA. PHFs labeled/dated. Offsite label.,','8096'),('2954','2954','5','Time as a control. Operational plan,waiver/variance followed. Permit parameters followed.,,','8097'),('2955','2955','3','Kitchenware & FCS of equip. properly washed,rinsed,san. & air dried. San solution as required.,','8098'),('2956','2956','3','Person in charge available and knowledgeable/management certification,','8099'),('3046','3046','5','Approved water source with required documentation.,','8100'),('3047','3047','5','Required E-Coli lab testing documented. (NAC 445A.555 a),','8101'),('3048','3048','5','Required Annual & 4-year series lab testing documented. (NAC 445A. 555 b&c),','8102'),('3049','3049','3','Container testing conducted every three months. (NAC 445A.563),','8103'),('3050','3050','3','Pre and Post Water testing conducted as required. ( NAC445A.557),','8104'),('3064','3064','3','Proper labeling of food for consumption off site and/or transportation.,','8105'),('3065','3065','3','Person in charge available and knowledgeable/management certification.Facility has an effective employee health policy.,','8106'),('3066','3066','3','Grade card and required signs posted conspicuously. Records/logs maintained and available when required. NCIAA compliant.,','8107'),('3067','3067','0','Appropriate sanitizer test kits provided and used. Ware washing thermometer(s) are required. Wiping cloths and linens stored and used properly. Permanently affixed thermometers.,','8108'),('3068','3068','0','Facility in sound condition and maintained (floors,walls,ceilings,plumbing,lighting,ventilation,etc.)','8109'),('3069','3069','5','Operational plan,HACCP plan,waiver or variance approved and followed when required. Operating within the parameters of the health permit.,','8110'),('4177','4177','0','Dumpsters lids open,','8111'),('4178','4178','0','Dumpsters located less than 50 ft from doors,','8112'),('4179','4179','0','Dumpster on soil or damaged pavement,','8113'),('4180','4180','0','Trash spillage around dumpsters,','8114'),('4181','4181','0','Outdoor trash cans with no lids,','8115'),('4182','4182','0','Weatherstripping and/or door sweeps in disrepair,','8116'),('4183','4183','0','Windows damaged and/or screens missing,','8117'),('4184','4184','0','Penetrations not sealed,','8118'),('4185','4185','0','Walls/roof line in disrepair,','8119'),('4186','4186','0','Ventilation intakes not screened,','8120'),('4187','4187','0','Water not adequately draining,','8121'),('4188','4188','0','Roof in disrepair,','8122'),('4189','4189','0','Gutters clogged,','8123'),('4190','4190','0','Other,','8124'),('4191','4191','0','Overgrown/Excessive vegetation,','8125'),('4192','4192','0','Trees/Vegetation in contact with building,','8126'),('4193','4193','0','Tree hazard observed,','8127'),('4194','4194','0','Overgrown/Excessive vegetation,','8128'),('4195','4195','0','Evidence of rodents,','8129'),('4196','4196','0','Evidence of nuisance birds,','8130'),('4197','4197','0','Other,','8131'),('4198','4198','0','General unsanitary conditions observed,','8132'),('4199','4199','0','General unsanitary conditions observed,','8133'),('4200','4200','0','General unsanitary conditions observed,','8134'),('4201','4201','0','General unsanitary conditions observed,','8135'),('4202','4202','0','Other,','8136'),('4203','4203','0','Evidence of rodents,','8137'),('4204','4204','0','Evidence of flies,','8138'),('4205','4205','0','Evidence of cockroaches,','8139'),('4206','4206','0','Other,','8140'),('4207','4207','0','Administrative procedures not followed as required,','8141'),('4208','4208','0','Sticky traps not serviced as needed,','8142'),('4209','4209','0','Light traps not serviced as needed,','8143'),('4210','4210','0','Bait stations not serviced as needed,','8144'),('4771','4771','0','Interruption of electrical service,','8145'),('4772','4772','0','No potable water or hot water,','8146'),('4773','4773','0','Gross unsanitary occurrences or conditions including pest infestation,','8147'),('4774','4774','0','Sewage or liquid waste not disposed of in an approved manner,','8148'),('4775','4775','0','Lack of adequate refrigeration,','8149'),('4776','4776','0','Lack of adequate employee toilets and handwashing facilities,','8150'),('4777','4777','0','Suspected foodborne illness outbreak,','8151'),('4778','4778','0','Other condition or circumstance that may endanger public health,','8152'),('4779','4779','5','Operating within the parameters of the health permit. Compliance with Time as a Public Health Control,waiver,specialized process,and Hazard Analysis Critical Control Point (HACCP) plan.,,','8153'),('4780','4780','5','Handwashing (as required,when required,proper glove use,no bare hand contact of ready to eat foods). Food handler health restrictions as required.,,','8154'),('4781','4781','5','Commercially manufactured food from approved source with required labels. Parasite destruction as required. Time temperature control for safety (TCS) food received at proper temperature.,','8155'),('4782','4782','5','Hot and cold running water from approved source as required.,','8156'),('4783','4783','5','No imminently dangerous cross connection,adequate backflow prevention. Wastewater and sewage properly disposed.,,','8157'),('4784','4784','5','Food wholesome,not spoiled,contaminated,or adulterated.,,','8158'),('4785','4785','5','TCS food cooked and reheated to proper temperatures.,','8159'),('4786','4786','5','TCS food properly cooled.,','8160'),('4787','4787','5','TCS food at proper temperatures.,','8161'),('4788','4788','3','Equipment approved,properly designed,maintained,and operated.,,','8162'),('4789','4789','3','Food protected from potential cross-contamination.,','8163'),('4790','4790','3','Chemicals properly identified,stored,and used.,','8164'),('4791','4791','3','Food protected from potential contamination by employees and consumers.,','8165'),('4792','4792','3','Food contact surfaces of equipment properly cleaned and sanitized. Sanitizer solution provided and maintained as required.,','8166'),('4793','4793','3','Adequate handwashing sinks stocked and accessible.,','8167'),('4794','4794','3','Effective pest control measures. Animals restricted as required.,','8168'),('4795','4795','3','Grade card posted conspicuously. Consumer advisory as required.,','8169'),('4796','4796','3','Thermometers provided and accurate.,','8170'),('4797','4797','3','TCS food thawed and cooled using proper methods. Fruits and vegetables washed prior to preparation or service.,','8171'),('4798','4798','3','Single-use/single-service items properly used.,','8172'),('4799','4799','3','Person in charge present,demonstrates knowledge,and performs duties. Effective employee health policy. Mandated certification and food handler card as required.,','8173'),('4800','4800','3','Proper backflow prevention devices in place and maintained.,','8174'),('4801','4801','3','TCS food labeled and dated as required. Food sold for offsite consumption labeled properly. Records,logs,policies,and procedures maintained and available when required.,,','8175'),('4802','4802','0','Personal cleanliness maintained. Personal effects properly stored.,','8176'),('4803','4803','0','Non-TCS food labeled and within shelf-life. Food stored off the floor. Proper retail storage of chemicals.,','8177'),('4804','4804','0','Ware washing facilities maintained. Wiping cloths properly stored,test strips available.,,','8178'),('4805','4805','0','Signs and certifications as required.,','8179'),('4806','4806','0','Small wares approved,properly designed,in good repair.,','8180'),('4807','4807','0','Utensils,equipment,linens,single-service/single-use items properly handled,stored,and dispensed.,','8181'),('4808','4808','0','Nonfood contact surfaces and equipment properly constructed,installed,maintained,and clean.,,','8182'),('4809','4809','0','Restrooms custodial areas,and premises maintained.,','8183'),('4810','4810','0','Physical facility in sound condition and maintained.,','8184');

============================== 6ae34e23-17ec-44dc-b901-2b3d2d41d1dc ==============================
-- created_at: 2026-03-20T16:56:22.633468322+00:00
-- finished_at: 2026-03-20T16:56:22.800141934+00:00
-- elapsed: 166ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c32878-0308-29ec-0023-c553000451be
-- desc: execute adapter call
show terse schemas in database PC_DBT_DB
    limit 10000
/* {"app": "dbt", "connection_name": "", "dbt_version": "2.0.0", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:56:22.808266190+00:00
-- finished_at: 2026-03-20T16:56:23.001194305+00:00
-- elapsed: 192ms
-- outcome: success
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: 01c32878-0308-28d7-0023-c5530002fbd2
-- desc: get_relation > list_relations call
SHOW OBJECTS IN SCHEMA "PC_DBT_DB"."DBT_EAPPEL" LIMIT 10000;
-- created_at: 2026-03-20T16:56:23.003866246+00:00
-- finished_at: 2026-03-20T16:56:23.402097093+00:00
-- elapsed: 398ms
-- outcome: success
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: 01c32878-0308-2a04-0023-c553000441d2
-- desc: execute adapter call
drop table if exists "PC_DBT_DB"."DBT_EAPPEL"."VIOLATION_CODES" cascade
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "seed.elvis.violation_codes", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:56:23.406232906+00:00
-- finished_at: 2026-03-20T16:56:23.778142026+00:00
-- elapsed: 371ms
-- outcome: success
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: 01c32878-0308-26c9-0023-c5530003f2ce
-- desc: execute adapter call
create table PC_DBT_DB.dbt_EAppel.violation_codes (VIOLATION_ID integer,VIOLATION_CODE varchar,VIOLATION_DEMERITS integer,VIOLATION_DESCRIPTION varchar,OBJECTID integer)
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "seed.elvis.violation_codes", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T16:56:23.781289810+00:00
-- finished_at: 2026-03-20T16:56:23.917856528+00:00
-- elapsed: 136ms
-- outcome: success
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: 01c32878-0308-28d8-0023-c5530003e3a2
-- desc: add_query adapter call
BEGIN;
-- created_at: 2026-03-20T16:56:23.920026344+00:00
-- finished_at: 2026-03-20T16:56:24.907566269+00:00
-- elapsed: 987ms
-- outcome: success
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: 01c32878-0308-2621-0023-c5530002cf1a
-- desc: add_query adapter call
insert into PC_DBT_DB.dbt_EAppel.violation_codes (VIOLATION_ID, VIOLATION_CODE, VIOLATION_DEMERITS, VIOLATION_DESCRIPTION, OBJECTID) values
            ('1','1','6','Food not obtained from approved sources and/or improperly identified.','7972'),('2','2','6','Food spoiled or adulterated.','7973'),('3','3','6','Employee(s) working with boils,infected wounds,respiratory,infections and/or other communicable diseases.,','7974'),('4','4','4','Inadequate hot and cold holding equipment,improperly designed,maintained and/or operated.,','7975'),('5','5','10','Hot potentially hazardous foods not rapidly cooled by approved methods.,,','7976'),('7','7','2','Potentially hazardous foods improperly thawed.,','7977'),('8','8','3','Potentially hazardous salads and/or fillings not made with prechilled ingredients.,','7978'),('9','9','2','Perishable foods kept at improper temperature.,','7979'),('10','10','3','Suitable thermometers (stem,cooler,oven) not provided and/or inadequately used.,','7980'),('12','12','6','Food workers improperly washing hands after using toilet,coughing,eating,smoking,after handling raw animal products and/or otherwise contaminating their hands.Inadequatefacilities.,','7981'),('13','13','3','Unsuitable hand washing facilities,unclean,inaccessible and/or not in good repair,with unapproved soap,towels and/or waste receptacles not provided.,','7982'),('14','14','4','Kitchenware and/or food contact surfaces of equipment improperly cleaned,sanitized and/or air dried.,,','7983'),('15','15','6','Sewage not disposed into public sewer or approved facility. Cross-connections or back siphonage present.,','7984'),('16','16','6','No hot and cold running water as required and/or water not from an approved source.,','7985'),('17','17','2','Fruits and vegetables improperly washed prior to serving.,','7986'),('18','18','1','Foods not stored off the floor.,','7987'),('19','19','1','Required labels not present on food or containers of food.Required signs not posted.,','7988'),('20','20','1','Health cards not current on all food handlers.,','7989'),('21','21','1','Unacceptable hygienic practices,unclean outer garments,improper hair restraints used.,','7990'),('22','22','1','In-use utensils improperly handled and/or stored.,','7991'),('23','23','1','Facilities for washing and sanitizing equipment and utensils unapproved,inadequate,improperly constructed,maintained and/or operated.,,','7992'),('24','24','1','Accurate thermometers,chemical tests kits,and/or pressure gauges not present and/or working.,','7993'),('25','25','1','Clean utensils,equipment and/or singe service items improperly handled,stored and/or dispensed.,','7994'),('26','26','3','Single service items reused.,','7995'),('27','27','1','Unclean wiping cloths,stored in an unapproved sanitizer,and/or unrestricted in use.,','7996'),('28','28','1','Unapproved food contact surfaces. Food contact surfaces notsmooth,easily cleanable,properly constructed and/or installed.,','7997'),('29','29','1','Plastic used for food contact surfaces is not of approved food grade quality.,','7998'),('30','30','1','Non-food contact surfaces improperly constructed and/or installed.,','7999'),('31','31','1','Non-food contact surfaces and/or cooking devices not maintained and/or unclean.,','8000'),('32','32','1','Toilet facilities for employees inadequate,inconvenient,unclean and/or not in good repair.Covered trash cans not provided.Doors not self-closing.,','8001'),('33','33','1','Garbage storage and/or removal inadequate and/or unclean.Garbage containers not clean,pest proof,non-absorbent and covered.Wash area unclean and/or not maintained.,','8002'),('34','34','3','No effective measures to control pests.Pest control devices not maintained.,','8003'),('35','35','1','Improper lighting and/or ventilation,ventilation hoods and/or filters improperly cleaned and/or maintained.,,','8004'),('36','36','1','Plumbing and/or fixtures improperly sized,installed and/or maintained. Plumbing and/or fixtures improperly drained.,,','8005'),('37','37','1','Floors,walls,ceilings,improperly constructed and/or installed.Not in good repair and/or clean.,,','8006'),('38','38','1','Living quarters not completely separated from food service.Infant or child care allowed.Premises not maintained free of litter,unnecessary equipment and/or personal effects.,,','8007'),('39','39','1','Live animals not in compliance with current Regulations.,','8008'),('40','40','1','Non-compliant with Nevada Revised Statute 202.2483 regarding smoking.,','8009'),('61','1-Jun','6','Poultry,poultry stuffing,stuffed meats,stuffing containing meats,casseroles containing potentially hazardous foods and/or food to be reheated containing potentially hazardous food not cooked to an internal temperature of 165°F.,','8010'),('62','2-Jun','6','Ground,fabricated and/or restructured meats not cooked throughout to 155&deg,F.,','8011'),('63','3-Jun','6','Pork and/or any food containing pork,not cooked to an internal temperature of 155&deg,F or above.,','8012'),('64','4-Jun','6','Potentially hazardous foods not kept at 40&deg,F or colder or at 140&deg,F or hotter,except during necessary preparation procedures.,,','8013'),('111','1-Nov','4','Food unprotected from cross-contamination by raw meats,poultry,fish,seafood and/or raw eggs.,,','8014'),('112','2-Nov','4','Food unprotected from cross-contamination by food handlers.,','8015'),('113','3-Nov','4','Food unprotected from cross-contamination by chemicals.,','8016'),('114','4-Nov','4','Food unprotected by cross-contamination by proper storage.,','8017'),('201','1','5','Verifiable time as a control with approved procedure when in use. Operational plan,HACCP plan,waiver or variance approved and followed when required. Nevada Clean Indoor Air Act compliant.,','8018'),('202','2','5','Handwashing (as required,when required,proper glove use,no bare hand contact of ready to eat foods).Foodhandler health restrictions as required.,,','8019'),('203','3','5','Commercially manufactured food from approved source with required labels. Parasite destruction as required. Potentially hazardous foods/time temperature control for safety (PHF/TCS) received at proper temperature.,','8020'),('204','4','5','Hot and cold running water from approved source as required.,','8021'),('205','5','5','Imminently dangerous cross connection or backflow.Waste water and sewage disposed into public sewer or approved facility.,','8022'),('206','6','5','Food wholesome,not spoiled,contaminated,or adulterated.,,','8023'),('207','7','5','PHF/TCSs cooked and reheated to proper temperatures.,','8024'),('208','8','5','PHF/TCSs properly cooled.,','8025'),('209','9','5','PHF/TCSs at proper temperatures during storage,display,service,transport,and holding. ,','8026'),('210','10','5','Operating within the parameters of the health permit.,','8027'),('211','11','3','Food protected from potential contamination during storage and preparation.,','8028'),('212','12','3','Food protected from potential contamination by chemicals. Toxic items properly labeled,stored and used.,,','8029'),('213','13','3','Food protected from potential contamination by employees and consumers.,','8030'),('214','14','3','Kitchenware and food contact surfaces of equipment properly washed,rinsed,sanitized and air dried.Sanitizer solution provided and maintained as required.,','8031'),('215','15','3','Handwashing facilities adequate in number,stocked,accessible,and limited to handwashing only.,,','8032'),('216','16','3','Effective pest control measures. Animals restricted as required.,','8033'),('217','17','3','Hot and cold holding equipment present,properly designed,maintained and operated.,','8034'),('218','18','3','Accurate thermometers (stem & hot/cold holding) provided and used.,','8035'),('219','19','3','PHF/TCSs properly thawed.,','8036'),('220','20','3','Single use items not reused or misused.,','8037'),('221','21','3','Person in charge available and knowledgeable/management certification.,','8038'),('222','22','3','Backflow prevention devices and methods in place and maintained.,','8039'),('223','23','3','B or C" grade card and required signs posted conspicuously. Consumer advisory as required. Records/logs maintained and available when required.,"','8040'),('224','24','1','Acceptable personal hygiene practices,clean outer garments,proper hair restraints used. Living quarters and child care completely separated from food service.,','8041'),('225','25','1','Food and food storage containers properly labeled and dated as required. Food stored off the floor when required. Non-PHF/TCS not spoiled and within shelf-life. Proper retail storage of chemicals.,','8042'),('226','26','1','Facilities for washing and sanitizing kitchenware approved,adequate,properly constructed,maintained and operated. ,,','8043'),('227','27','1','Appropriate sanitizer test kits provided and used. Ware washing thermometer(s) as required. Wiping cloths & linens stored and used properly.,','8044'),('228','28','1','Food contact surfaces and equipment approved,food grade material,smooth,easily cleanable,properly constructed and installed.,','8045'),('229','29','1','Utensils,equipment,and single serve items properly handled,stored,and dispensed.,','8046'),('230','30','1','Nonfood contact surfaces and equipment properly constructed,installed,maintained and clean.,','8047'),('231','31','1','Health cards as required. Foodhandler not aware of employee health policy. A" grade card posted conspicuously. ,"','8048'),('232','32','1','Restrooms,mop sink,and custodial areas maintained and clean.Premises maintained free of litter,unnecessary equipment,or personal effects. Trash areas adequate,pest proof,and clean.','8049'),('233','33','1','Facility in sound condition and maintained (floors,walls,ceilings,plumbing,lighting,ventilation,etc.).','8050'),('234','34','1','Fruits and vegetables washed prior to preparation or service.,','8051'),('301','IHH-1','0','Imminent Health Hazard - (Immediate Closure) - Interruption of electrical service,','8052'),('302','IHH-2','0','Imminent Health Hazard - (Immediate Closure) - No potable water or hot water,','8053'),('303','IHH-3','0','Imminent Health Hazard - (Immediate Closure) - Gross unsanitary occurrences or conditions including pest infestation,','8054'),('304','IHH-4','0','Imminent Health Hazard - (Immediate Closure) - Sewage or liquid waste not disposed of in an approved manner,','8055'),('305','IHH-5','0','Imminent Health Hazard - (Immediate Closure) - Lack of adequate refrigeration,','8056'),('306','IHH-6','0','Imminent Health Hazard - (Immediate Closure) - Lack of adequate employee toilets and handwashing facilities,','8057'),('307','IHH-7','0','Imminent Health Hazard - (Immediate Closure) - Misuse of poisonous or toxic materials,','8058'),('308','IHH-8','0','Imminent Health Hazard - (Immediate Closure) - Suspected foodborne illness outbreak,','8059'),('309','IHH-9','0','Imminent Health Hazard - (Immediate Closure) - Emergency such as fire and/or flood,','8060'),('310','IHH-10','0','Imminent Health Hazard - (Immediate Closure) - Other condition or circumstance that may endanger public health,','8061'),('2907','2907','3','Food and warewashing equipment approved,properly designed,constructed and installed.,','8062'),('2908','2908','3','PHF/TCSs properly thawed. Fruits and vegetables washed prior to preparation or service.,','8063'),('2909','2909','3','Grade/card signs posted. Consumer advisory. Records/logs. NCIAA. PHFs labeled/dated. Offsite label.,','8064'),('2910','2910','0','Non-PHF labeled/dated/not spoiled/within shelf-life. Food stored off-floor. Retail chemical storage.,','8065'),('2911','2911','0','Sanitizer kits available. Equip. & ware washing therm. as required. Wiping cloths and linen use.,','8066'),('2912','2912','0','Small wares and portable appliances approved,properly designed,in good repair.,','8067'),('2925','2925','0','Acceptable personal hygiene,clean garments,hair restraints. Living quarters & child care separate.,','8068'),('2926','2926','0','Ware washing facilities approved,adequate,properly constructed,maintained & operated.,,','8069'),('2927','2927','0','Utensils,equipment,and single serve items properly handled,stored,and dispensed.,','8070'),('2928','2928','0','Nonfood contact surfaces and equipment properly constructed,installed,maintained and clean.,','8071'),('2929','2929','0','RR''s,mop sk,cust. areasclean/maint. No litter,unnec. equip,pers items. Trash area clean/maint.,','8072'),('2930','2930','0','Facility maintained (floors,walls,ceilings,plumbing,lighting,ventilation,etc.).','8073'),('2931','2931','0','Time as a control. Operational plan,waiver/variance followed. Permit parameters followed.,,','8074'),('2932','2932','0','Hand washing as required,no bare hand w/ RTE foods. Foodhandler health restrictions as required.,,','8075'),('2933','2933','0','Food from an approved source w/ proper labels. Parasite destruction. PHF''s received @ proper temp.,','8076'),('2934','2934','0','Hot & cold running water from an approved source as required.,','8077'),('2935','2935','0','Imminently dangerous cross connection or backflow. Waste water and sewage properly disposed of.,','8078'),('2936','2936','0','Food wholesome,not spoiled,contaminated,or adulterated.,,','8079'),('2937','2937','0','PHF/TCSs cooked and reheated to proper temperature.,','8080'),('2938','2938','0','PHF/TCSs properly cooled.,','8081'),('2939','2939','0','PHF/TCSs maintained at proper temperature.,','8082'),('2940','2940','0','Food protected from potential contamination during storage and preparation.,','8083'),('2941','2941','0','Food protected from potential contamination by chemicals. Toxic items labeled,stored & used.,,','8084'),('2942','2942','0','Food protected from potential contamination by employees and consumers.,','8085'),('2943','2943','0','Kitchenware & FCS of equip. properly washed,rinsed,san. & air dried. San solution as required.,','8086'),('2944','2944','0','Handwashing facilities adequate in number,stocked,accessible,and limited to handwashing only.,,','8087'),('2945','2945','0','Effective pest control measures. Animals restricted as required.,','8088'),('2946','2946','0','Hot and cold holding equipment present,properly designed,maintained and operated.,','8089'),('2947','2947','0','Accurate thermometers (stem & hot/cold holding) provided and used.,','8090'),('2948','2948','0','Single use items not reused or misused.,','8091'),('2949','2949','0','Person in charge available and knowledgeable/management certification.,','8092'),('2950','2950','0','Backflow prevention devices and methods in place and maintained.,','8093'),('2951','2951','0','Food and warewashing equipment approved,properly designed,constructed and installed.,','8094'),('2952','2952','0','PHF/TCSs properly thawed. Fruits and vegetables washed prior to preparation of service.,','8095'),('2953','2953','0','Grade card/signs posted. Consumer advisory. Records/logs. NCIAA. PHFs labeled/dated. Offsite label.,','8096'),('2954','2954','5','Time as a control. Operational plan,waiver/variance followed. Permit parameters followed.,,','8097'),('2955','2955','3','Kitchenware & FCS of equip. properly washed,rinsed,san. & air dried. San solution as required.,','8098'),('2956','2956','3','Person in charge available and knowledgeable/management certification,','8099'),('3046','3046','5','Approved water source with required documentation.,','8100'),('3047','3047','5','Required E-Coli lab testing documented. (NAC 445A.555 a),','8101'),('3048','3048','5','Required Annual & 4-year series lab testing documented. (NAC 445A. 555 b&c),','8102'),('3049','3049','3','Container testing conducted every three months. (NAC 445A.563),','8103'),('3050','3050','3','Pre and Post Water testing conducted as required. ( NAC445A.557),','8104'),('3064','3064','3','Proper labeling of food for consumption off site and/or transportation.,','8105'),('3065','3065','3','Person in charge available and knowledgeable/management certification.Facility has an effective employee health policy.,','8106'),('3066','3066','3','Grade card and required signs posted conspicuously. Records/logs maintained and available when required. NCIAA compliant.,','8107'),('3067','3067','0','Appropriate sanitizer test kits provided and used. Ware washing thermometer(s) are required. Wiping cloths and linens stored and used properly. Permanently affixed thermometers.,','8108'),('3068','3068','0','Facility in sound condition and maintained (floors,walls,ceilings,plumbing,lighting,ventilation,etc.)','8109'),('3069','3069','5','Operational plan,HACCP plan,waiver or variance approved and followed when required. Operating within the parameters of the health permit.,','8110'),('4177','4177','0','Dumpsters lids open,','8111'),('4178','4178','0','Dumpsters located less than 50 ft from doors,','8112'),('4179','4179','0','Dumpster on soil or damaged pavement,','8113'),('4180','4180','0','Trash spillage around dumpsters,','8114'),('4181','4181','0','Outdoor trash cans with no lids,','8115'),('4182','4182','0','Weatherstripping and/or door sweeps in disrepair,','8116'),('4183','4183','0','Windows damaged and/or screens missing,','8117'),('4184','4184','0','Penetrations not sealed,','8118'),('4185','4185','0','Walls/roof line in disrepair,','8119'),('4186','4186','0','Ventilation intakes not screened,','8120'),('4187','4187','0','Water not adequately draining,','8121'),('4188','4188','0','Roof in disrepair,','8122'),('4189','4189','0','Gutters clogged,','8123'),('4190','4190','0','Other,','8124'),('4191','4191','0','Overgrown/Excessive vegetation,','8125'),('4192','4192','0','Trees/Vegetation in contact with building,','8126'),('4193','4193','0','Tree hazard observed,','8127'),('4194','4194','0','Overgrown/Excessive vegetation,','8128'),('4195','4195','0','Evidence of rodents,','8129'),('4196','4196','0','Evidence of nuisance birds,','8130'),('4197','4197','0','Other,','8131'),('4198','4198','0','General unsanitary conditions observed,','8132'),('4199','4199','0','General unsanitary conditions observed,','8133'),('4200','4200','0','General unsanitary conditions observed,','8134'),('4201','4201','0','General unsanitary conditions observed,','8135'),('4202','4202','0','Other,','8136'),('4203','4203','0','Evidence of rodents,','8137'),('4204','4204','0','Evidence of flies,','8138'),('4205','4205','0','Evidence of cockroaches,','8139'),('4206','4206','0','Other,','8140'),('4207','4207','0','Administrative procedures not followed as required,','8141'),('4208','4208','0','Sticky traps not serviced as needed,','8142'),('4209','4209','0','Light traps not serviced as needed,','8143'),('4210','4210','0','Bait stations not serviced as needed,','8144'),('4771','4771','0','Interruption of electrical service,','8145'),('4772','4772','0','No potable water or hot water,','8146'),('4773','4773','0','Gross unsanitary occurrences or conditions including pest infestation,','8147'),('4774','4774','0','Sewage or liquid waste not disposed of in an approved manner,','8148'),('4775','4775','0','Lack of adequate refrigeration,','8149'),('4776','4776','0','Lack of adequate employee toilets and handwashing facilities,','8150'),('4777','4777','0','Suspected foodborne illness outbreak,','8151'),('4778','4778','0','Other condition or circumstance that may endanger public health,','8152'),('4779','4779','5','Operating within the parameters of the health permit. Compliance with Time as a Public Health Control,waiver,specialized process,and Hazard Analysis Critical Control Point (HACCP) plan.,,','8153'),('4780','4780','5','Handwashing (as required,when required,proper glove use,no bare hand contact of ready to eat foods). Food handler health restrictions as required.,,','8154'),('4781','4781','5','Commercially manufactured food from approved source with required labels. Parasite destruction as required. Time temperature control for safety (TCS) food received at proper temperature.,','8155'),('4782','4782','5','Hot and cold running water from approved source as required.,','8156'),('4783','4783','5','No imminently dangerous cross connection,adequate backflow prevention. Wastewater and sewage properly disposed.,,','8157'),('4784','4784','5','Food wholesome,not spoiled,contaminated,or adulterated.,,','8158'),('4785','4785','5','TCS food cooked and reheated to proper temperatures.,','8159'),('4786','4786','5','TCS food properly cooled.,','8160'),('4787','4787','5','TCS food at proper temperatures.,','8161'),('4788','4788','3','Equipment approved,properly designed,maintained,and operated.,,','8162'),('4789','4789','3','Food protected from potential cross-contamination.,','8163'),('4790','4790','3','Chemicals properly identified,stored,and used.,','8164'),('4791','4791','3','Food protected from potential contamination by employees and consumers.,','8165'),('4792','4792','3','Food contact surfaces of equipment properly cleaned and sanitized. Sanitizer solution provided and maintained as required.,','8166'),('4793','4793','3','Adequate handwashing sinks stocked and accessible.,','8167'),('4794','4794','3','Effective pest control measures. Animals restricted as required.,','8168'),('4795','4795','3','Grade card posted conspicuously. Consumer advisory as required.,','8169'),('4796','4796','3','Thermometers provided and accurate.,','8170'),('4797','4797','3','TCS food thawed and cooled using proper methods. Fruits and vegetables washed prior to preparation or service.,','8171'),('4798','4798','3','Single-use/single-service items properly used.,','8172'),('4799','4799','3','Person in charge present,demonstrates knowledge,and performs duties. Effective employee health policy. Mandated certification and food handler card as required.,','8173'),('4800','4800','3','Proper backflow prevention devices in place and maintained.,','8174'),('4801','4801','3','TCS food labeled and dated as required. Food sold for offsite consumption labeled properly. Records,logs,policies,and procedures maintained and available when required.,,','8175'),('4802','4802','0','Personal cleanliness maintained. Personal effects properly stored.,','8176'),('4803','4803','0','Non-TCS food labeled and within shelf-life. Food stored off the floor. Proper retail storage of chemicals.,','8177'),('4804','4804','0','Ware washing facilities maintained. Wiping cloths properly stored,test strips available.,,','8178'),('4805','4805','0','Signs and certifications as required.,','8179'),('4806','4806','0','Small wares approved,properly designed,in good repair.,','8180'),('4807','4807','0','Utensils,equipment,linens,single-service/single-use items properly handled,stored,and dispensed.,','8181'),('4808','4808','0','Nonfood contact surfaces and equipment properly constructed,installed,maintained,and clean.,,','8182'),('4809','4809','0','Restrooms custodial areas,and premises maintained.,','8183'),('4810','4810','0','Physical facility in sound condition and maintained.,','8184');
-- created_at: 2026-03-20T16:56:24.908968910+00:00
-- finished_at: 2026-03-20T16:56:25.258944115+00:00
-- elapsed: 349ms
-- outcome: success
-- dialect: snowflake
-- node_id: seed.elvis.violation_codes
-- query_id: 01c32878-0308-238f-0023-c55300047136
-- desc: add_query adapter call
COMMIT;

============================== 277d9e00-65ae-453c-99ac-411cc28fc9a3 ==============================
-- created_at: 2026-03-20T17:01:05.494813960+00:00
-- finished_at: 2026-03-20T17:01:05.664378430+00:00
-- elapsed: 169ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c3287d-0308-2467-0023-c55300026e9e
-- desc: Get table schema
describe table "PC_DBT_DB"."DBT_EAPPEL"."STG_SNHD_INSPECTIONS";
-- created_at: 2026-03-20T17:01:05.523242688+00:00
-- finished_at: 2026-03-20T17:01:05.728425807+00:00
-- elapsed: 205ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c3287d-0308-2a04-0023-c553000441e6
-- desc: Get table schema
describe table "PC_DBT_DB"."DBT_EAPPEL"."VIOLATION_CODES";
-- created_at: 2026-03-20T17:01:06.631472618+00:00
-- finished_at: 2026-03-20T17:01:06.794140250+00:00
-- elapsed: 162ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c3287d-0308-28d8-0023-c5530003e3ae
-- desc: execute adapter call
show terse schemas in database PC_DBT_DB
    limit 10000
/* {"app": "dbt", "connection_name": "", "dbt_version": "2.0.0", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T17:01:07.347675023+00:00
-- finished_at: 2026-03-20T17:01:07.559460005+00:00
-- elapsed: 211ms
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.stg_violation_codes
-- query_id: 01c3287d-0308-238f-0023-c5530004714a
-- desc: get_relation > list_relations call
SHOW OBJECTS IN SCHEMA "PC_DBT_DB"."DBT_EAPPEL" LIMIT 10000;
-- created_at: 2026-03-20T17:01:07.561572314+00:00
-- finished_at: 2026-03-20T17:01:08.205753783+00:00
-- elapsed: 644ms
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.stg_violation_codes
-- query_id: 01c3287d-0308-29ec-0023-c553000451c6
-- desc: execute adapter call
create or replace   view PC_DBT_DB.dbt_EAppel.stg_violation_codes
  
  
  
  
  as (
    with source as (
    select * from PC_DBT_DB.dbt_EAppel.violation_codes
),

renamed as (
    select
        violation_id,
        violation_code,
        violation_demerits,
        violation_description,
        objectid
    from source
)

select * from renamed
  )
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.elvis.stg_violation_codes", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T17:01:08.210166988+00:00
-- finished_at: 2026-03-20T17:01:11.612895703+00:00
-- elapsed: 3.4s
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.mart_top_violations
-- query_id: 01c3287d-0308-28d7-0023-c5530002fbe6
-- desc: execute adapter call
create or replace transient  table PC_DBT_DB.dbt_EAppel.mart_top_violations
    
    
    
    as (

with inspections as (
    select * from PC_DBT_DB.dbt_EAppel.stg_snhd_inspections
    where violation_codes is not null
      and violation_codes != ''
      and inspection_date is not null
),

flattened as (
    select
        i.category_name,
        i.inspection_type,
        i.inspection_grade,
        i.inspection_date,
        trim(v.value::varchar) as violation_code
    from inspections i,
    lateral flatten(input => split(i.violation_codes, '|')) v
),

codes as (
    select * from PC_DBT_DB.dbt_EAppel.stg_violation_codes
)

select
    f.violation_code,
    c.violation_description,
    c.violation_demerits,
    f.category_name,
    f.inspection_type,
    count(*) as occurrence_count
from flattened f
left join codes c on f.violation_code = c.violation_code::varchar
where f.violation_code != ''
group by 1, 2, 3, 4, 5
order by occurrence_count desc
    )

/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.elvis.mart_top_violations", "profile_name": "user", "target_name": "default"} */;

============================== e3521b61-90fc-4b7f-b62a-3aea6f30feba ==============================
-- created_at: 2026-03-20T18:58:32.228953433+00:00
-- finished_at: 2026-03-20T18:58:32.581531150+00:00
-- elapsed: 352ms
-- outcome: error
-- error vendor code: 2003
-- error message: NotFound: [Snowflake] 002003 (42S02): SQL compilation error:
Table 'PC_DBT_DB.DBT_EAPPEL.STG_ART_WORK_POINTS' does not exist or not authorized.
-- dialect: snowflake
-- node_id: not available
-- query_id: not available
-- desc: Get table schema
describe table "PC_DBT_DB"."DBT_EAPPEL"."STG_ART_WORK_POINTS";
-- created_at: 2026-03-20T18:58:34.394201168+00:00
-- finished_at: 2026-03-20T18:58:34.555748820+00:00
-- elapsed: 161ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c328f2-0308-29ec-0023-c55300045792
-- desc: execute adapter call
show terse schemas in database PC_DBT_DB
    limit 10000
/* {"app": "dbt", "connection_name": "", "dbt_version": "2.0.0", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T18:58:35.034050110+00:00
-- finished_at: 2026-03-20T18:58:35.301431880+00:00
-- elapsed: 267ms
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.mart_art_work_points
-- query_id: 01c328f2-0308-2a04-0023-c55300044786
-- desc: get_relation > list_relations call
SHOW OBJECTS IN SCHEMA "PC_DBT_DB"."DBT_EAPPEL" LIMIT 10000;
-- created_at: 2026-03-20T18:58:35.304008375+00:00
-- finished_at: 2026-03-20T18:58:35.465627142+00:00
-- elapsed: 161ms
-- outcome: error
-- error vendor code: 2003
-- error message: NotFound: [Snowflake] 002003 (42S02): SQL compilation error:
Object 'PC_DBT_DB.DBT_EAPPEL.STG_ART_WORK_POINTS' does not exist or not authorized.
-- dialect: snowflake
-- node_id: model.elvis.mart_art_work_points
-- query_id: not available
-- desc: execute adapter call
create or replace transient  table PC_DBT_DB.dbt_EAppel.mart_art_work_points
    
    
    
    as (

with artworks as (
    select * from PC_DBT_DB.dbt_EAppel.stg_art_work_points
)

select
    objectid,
    artwork_name,
    artist,
    medium,
    location_detail,
    address,
    ward,
    latitude,
    longitude,
    pic_url,
    thumb_url
from artworks
order by ward, artwork_name
    )

/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.elvis.mart_art_work_points", "profile_name": "user", "target_name": "default"} */;

============================== a7678274-1216-45ab-aa25-9d2240464878 ==============================

============================== da20629c-b71d-49ff-a34d-c66553f9a140 ==============================
-- created_at: 2026-03-20T19:04:25.387662533+00:00
-- finished_at: 2026-03-20T19:04:25.597091857+00:00
-- elapsed: 209ms
-- outcome: error
-- error vendor code: 2003
-- error message: NotFound: [Snowflake] 002003 (42S02): SQL compilation error:
Table 'PC_DBT_DB.DBT_EAPPEL.STG_ART_WORK_POINTS' does not exist or not authorized.
-- dialect: snowflake
-- node_id: not available
-- query_id: not available
-- desc: Get table schema
describe table "PC_DBT_DB"."DBT_EAPPEL"."STG_ART_WORK_POINTS";
-- created_at: 2026-03-20T19:04:27.482366024+00:00
-- finished_at: 2026-03-20T19:04:27.615231573+00:00
-- elapsed: 132ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c328f8-0308-28d8-0023-c5530003ea7a
-- desc: execute adapter call
show terse schemas in database PC_DBT_DB
    limit 10000
/* {"app": "dbt", "connection_name": "", "dbt_version": "2.0.0", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T19:04:28.108320720+00:00
-- finished_at: 2026-03-20T19:04:28.306029993+00:00
-- elapsed: 197ms
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.mart_art_work_points
-- query_id: 01c328f8-0308-29eb-0023-c55300041a22
-- desc: get_relation > list_relations call
SHOW OBJECTS IN SCHEMA "PC_DBT_DB"."DBT_EAPPEL" LIMIT 10000;
-- created_at: 2026-03-20T19:04:28.308625355+00:00
-- finished_at: 2026-03-20T19:04:28.519666431+00:00
-- elapsed: 211ms
-- outcome: error
-- error vendor code: 2003
-- error message: NotFound: [Snowflake] 002003 (42S02): SQL compilation error:
Object 'PC_DBT_DB.DBT_EAPPEL.STG_ART_WORK_POINTS' does not exist or not authorized.
-- dialect: snowflake
-- node_id: model.elvis.mart_art_work_points
-- query_id: not available
-- desc: execute adapter call
create or replace transient  table PC_DBT_DB.dbt_EAppel.mart_art_work_points
    
    
    
    as (

with artworks as (
    select * from PC_DBT_DB.dbt_EAppel.stg_art_work_points
)

select
    objectid,
    artwork_name,
    artist,
    medium,
    location_detail,
    address,
    ward,
    latitude,
    longitude,
    pic_url,
    thumb_url
from artworks
order by ward, artwork_name
    )

/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.elvis.mart_art_work_points", "profile_name": "user", "target_name": "default"} */;

============================== ef5fa462-d57d-4ada-92ca-d106d537c372 ==============================
-- created_at: 2026-03-20T19:05:06.512950012+00:00
-- finished_at: 2026-03-20T19:05:06.836537816+00:00
-- elapsed: 323ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c328f9-0308-29ec-0023-c5530004590a
-- desc: Get table schema
describe table "PC_DBT_DB"."RAW"."ART_WORK_POINTS";
-- created_at: 2026-03-20T19:05:07.903225108+00:00
-- finished_at: 2026-03-20T19:05:08.038187714+00:00
-- elapsed: 134ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c328f9-0308-26c9-0023-c5530003f9ca
-- desc: execute adapter call
show terse schemas in database PC_DBT_DB
    limit 10000
/* {"app": "dbt", "connection_name": "", "dbt_version": "2.0.0", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T19:05:08.692964157+00:00
-- finished_at: 2026-03-20T19:05:08.920595292+00:00
-- elapsed: 227ms
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.stg_art_work_points
-- query_id: 01c328f9-0308-28d8-0023-c5530003ea8e
-- desc: get_relation > list_relations call
SHOW OBJECTS IN SCHEMA "PC_DBT_DB"."DBT_EAPPEL" LIMIT 10000;
-- created_at: 2026-03-20T19:05:08.923076980+00:00
-- finished_at: 2026-03-20T19:05:09.794391342+00:00
-- elapsed: 871ms
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.stg_art_work_points
-- query_id: 01c328f9-0308-29ec-0023-c5530004590e
-- desc: execute adapter call
create or replace   view PC_DBT_DB.dbt_EAppel.stg_art_work_points
  
  
  
  
  as (
    with source as (
    select * from PC_DBT_DB.RAW.art_work_points
),

renamed as (
    select
        objectid,
        name                                as artwork_name,
        trim(split_part(description, '|', 1)) as artist,
        trim(split_part(description, '|', 2)) as medium,
        trim(split_part(description, '|', 3)) as location_detail,
        trim(split_part(description, '|', 4)) as address,
        trim(split_part(description, '|', 5)) as ward,
        description                         as full_description,
        pic_url,
        thumb_url,
        icon_color,
        lat_1::float                        as latitude,
        long::float                         as longitude
    from source
)

select * from renamed
  )
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.elvis.stg_art_work_points", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T19:05:09.798610109+00:00
-- finished_at: 2026-03-20T19:05:12.984540427+00:00
-- elapsed: 3.2s
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.mart_art_work_points
-- query_id: 01c328f9-0308-24a8-0023-c553000503ee
-- desc: execute adapter call
create or replace transient  table PC_DBT_DB.dbt_EAppel.mart_art_work_points
    
    
    
    as (

with artworks as (
    select * from PC_DBT_DB.dbt_EAppel.stg_art_work_points
)

select
    objectid,
    artwork_name,
    artist,
    medium,
    location_detail,
    address,
    ward,
    latitude,
    longitude,
    pic_url,
    thumb_url
from artworks
order by ward, artwork_name
    )

/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.elvis.mart_art_work_points", "profile_name": "user", "target_name": "default"} */;

============================== 0d74f31b-1b40-4d0d-a01e-4ca1cfd7fa10 ==============================
-- created_at: 2026-03-20T21:49:29.403211809+00:00
-- finished_at: 2026-03-20T21:49:29.547022969+00:00
-- elapsed: 143ms
-- outcome: error
-- error vendor code: 2003
-- error message: NotFound: [Snowflake] 002003 (42S02): SQL compilation error:
Table 'PC_DBT_DB.DBT_EAPPEL.STG_FIRE_PREVENTION_INSPECTIONS' does not exist or not authorized.
-- dialect: snowflake
-- node_id: not available
-- query_id: not available
-- desc: Get table schema
describe table "PC_DBT_DB"."DBT_EAPPEL"."STG_FIRE_PREVENTION_INSPECTIONS";
-- created_at: 2026-03-20T21:49:29.537605252+00:00
-- finished_at: 2026-03-20T21:49:29.735694859+00:00
-- elapsed: 198ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c3299d-0308-28d7-0023-c5530005e4ee
-- desc: Get table schema
describe table "PC_DBT_DB"."DBT_EAPPEL"."STG_SNHD_INSPECTIONS";
-- created_at: 2026-03-20T21:49:29.742861327+00:00
-- finished_at: 2026-03-20T21:49:30.067628707+00:00
-- elapsed: 324ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c3299d-0308-28d8-0023-c55300054cbe
-- desc: Get table schema
describe table "PC_DBT_DB"."RAW"."EMPLOYEE_COMPENSATION";
-- created_at: 2026-03-20T21:49:31.420675492+00:00
-- finished_at: 2026-03-20T21:49:31.558086485+00:00
-- elapsed: 137ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c3299d-0308-28d7-0023-c5530005e4f2
-- desc: execute adapter call
show terse schemas in database PC_DBT_DB
    limit 10000
/* {"app": "dbt", "connection_name": "", "dbt_version": "2.0.0", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T21:49:32.147482526+00:00
-- finished_at: 2026-03-20T21:49:32.337689641+00:00
-- elapsed: 190ms
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.stg_employee_compensation
-- query_id: 01c3299d-0308-2a3c-0023-c55300061032
-- desc: get_relation > list_relations call
SHOW OBJECTS IN SCHEMA "PC_DBT_DB"."DBT_EAPPEL" LIMIT 10000;
-- created_at: 2026-03-20T21:49:32.340389568+00:00
-- finished_at: 2026-03-20T21:49:32.891627731+00:00
-- elapsed: 551ms
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.stg_employee_compensation
-- query_id: 01c3299d-0308-28d7-0023-c5530005e4f6
-- desc: execute adapter call
create or replace   view PC_DBT_DB.dbt_EAppel.stg_employee_compensation
  
  
  
  
  as (
    with source as (
    select * from PC_DBT_DB.RAW.employee_compensation
),

renamed as (
    select
        objectid,
        person_name,
        organization,
        split_part(organization, ' - ', 1)  as dept_code,
        job,
        work_group,
        left(year_ending, 4)::integer        as fiscal_year,
        gross_wages,
        base_salary,
        longevity_pay,
        overtime,
        other,
        annual_buybacks,
        pers_contributions,
        er_paid
    from source
)

select * from renamed
  )
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.elvis.stg_employee_compensation", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T21:49:33.292810971+00:00
-- finished_at: 2026-03-20T21:49:33.539495158+00:00
-- elapsed: 246ms
-- outcome: error
-- error vendor code: 2003
-- error message: NotFound: [Snowflake] 002003 (42S02): SQL compilation error:
Object 'PC_DBT_DB.DBT_EAPPEL.STG_FIRE_PREVENTION_INSPECTIONS' does not exist or not authorized.
-- dialect: snowflake
-- node_id: model.elvis.mart_fire_dept_staffing_vs_inspections
-- query_id: not available
-- desc: execute adapter call
create or replace transient  table PC_DBT_DB.dbt_EAppel.mart_fire_dept_staffing_vs_inspections
    
    
    
    as (

with fire_employees as (
    select
        fiscal_year,
        count(*)                            as headcount,
        round(sum(gross_wages), 2)         as total_payroll,
        round(avg(base_salary), 2)         as avg_base_salary,
        round(sum(overtime), 2)            as total_overtime
    from PC_DBT_DB.dbt_EAppel.stg_employee_compensation
    where dept_code = 'FR'
    group by 1
),

fire_inspections as (
    select
        fiscal_year,
        count(*)                            as property_inspection_periods,
        sum(inspections_conducted)          as total_inspections_conducted,
        sum(violations_written)             as total_violations_written,
        sum(unit_count)                     as total_units_in_scope,
        round(avg(pct_dwellings_with_violations), 2) as avg_pct_units_with_violations
    from PC_DBT_DB.dbt_EAppel.stg_fire_prevention_inspections
    group by 1
)

select
    coalesce(e.fiscal_year, i.fiscal_year)  as fiscal_year,
    e.headcount,
    e.total_payroll,
    e.avg_base_salary,
    e.total_overtime,
    i.property_inspection_periods,
    i.total_inspections_conducted,
    i.total_violations_written,
    i.total_units_in_scope,
    i.avg_pct_units_with_violations
from fire_employees e
full outer join fire_inspections i
    on e.fiscal_year = i.fiscal_year
order by fiscal_year
    )

/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.elvis.mart_fire_dept_staffing_vs_inspections", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T21:49:33.265589761+00:00
-- finished_at: 2026-03-20T21:49:35.489259425+00:00
-- elapsed: 2.2s
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.mart_job_pay_bands
-- query_id: 01c3299d-0308-2a04-0023-c55300059b32
-- desc: execute adapter call
create or replace transient  table PC_DBT_DB.dbt_EAppel.mart_job_pay_bands
    
    
    
    as (

with employees as (
    select * from PC_DBT_DB.dbt_EAppel.stg_employee_compensation
)

select
    job,
    work_group,
    fiscal_year,
    count(*)                                as headcount,
    round(min(base_salary), 2)             as min_base_salary,
    round(avg(base_salary), 2)             as avg_base_salary,
    round(max(base_salary), 2)             as max_base_salary,
    round(max(base_salary)
        - min(base_salary), 2)             as base_salary_spread,
    round(avg(gross_wages), 2)             as avg_gross_wages,
    round(avg(overtime), 2)               as avg_overtime
from employees
group by 1, 2, 3
having count(*) > 1
order by avg_base_salary desc
    )

/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.elvis.mart_job_pay_bands", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T21:49:33.312791131+00:00
-- finished_at: 2026-03-20T21:49:35.557416247+00:00
-- elapsed: 2.2s
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.mart_org_compensation_summary
-- query_id: 01c3299d-0308-2a3c-0023-c55300061036
-- desc: execute adapter call
create or replace transient  table PC_DBT_DB.dbt_EAppel.mart_org_compensation_summary
    
    
    
    as (

with employees as (
    select * from PC_DBT_DB.dbt_EAppel.stg_employee_compensation
)

select
    organization,
    dept_code,
    fiscal_year,
    count(*)                                                            as headcount,
    sum(gross_wages)                                                    as total_gross_wages,
    round(avg(base_salary), 2)                                         as avg_base_salary,
    min(base_salary)                                                    as min_base_salary,
    max(base_salary)                                                    as max_base_salary,
    sum(overtime)                                                       as total_overtime,
    round(sum(overtime) / nullif(sum(gross_wages), 0) * 100, 2)       as overtime_pct_of_payroll,
    sum(pers_contributions)                                             as total_pers_contributions
from employees
group by 1, 2, 3
order by organization, fiscal_year
    )

/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.elvis.mart_org_compensation_summary", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T21:49:33.317248095+00:00
-- finished_at: 2026-03-20T21:49:35.558002028+00:00
-- elapsed: 2.2s
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.mart_compensation_trends
-- query_id: 01c3299d-0308-29eb-0023-c55300056c86
-- desc: execute adapter call
create or replace transient  table PC_DBT_DB.dbt_EAppel.mart_compensation_trends
    
    
    
    as (

with employees as (
    select * from PC_DBT_DB.dbt_EAppel.stg_employee_compensation
)

select
    fiscal_year,
    count(*)                                                            as headcount,
    count(distinct organization)                                        as org_count,
    round(sum(gross_wages), 2)                                         as total_payroll,
    round(avg(gross_wages), 2)                                         as avg_gross_wages,
    round(avg(base_salary), 2)                                         as avg_base_salary,
    round(sum(overtime), 2)                                            as total_overtime,
    round(sum(overtime) / nullif(sum(gross_wages), 0) * 100, 2)       as overtime_pct_of_payroll,
    round(sum(pers_contributions), 2)                                  as total_pers_contributions,
    round(sum(longevity_pay), 2)                                       as total_longevity_pay
from employees
group by 1
order by 1
    )

/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.elvis.mart_compensation_trends", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T21:49:32.895956235+00:00
-- finished_at: 2026-03-20T21:49:35.640876143+00:00
-- elapsed: 2.7s
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.mart_overtime_analysis
-- query_id: 01c3299d-0308-28d8-0023-c55300054cc2
-- desc: execute adapter call
create or replace transient  table PC_DBT_DB.dbt_EAppel.mart_overtime_analysis
    
    
    
    as (

with employees as (
    select * from PC_DBT_DB.dbt_EAppel.stg_employee_compensation
)

select
    organization,
    dept_code,
    work_group,
    fiscal_year,
    count(*)                                                            as headcount,
    count(case when overtime > 0 then 1 end)                          as employees_with_overtime,
    round(sum(overtime), 2)                                            as total_overtime,
    round(avg(case when overtime > 0 then overtime end), 2)           as avg_overtime_per_earner,
    round(sum(base_salary), 2)                                         as total_base_salary,
    round(sum(overtime) / nullif(sum(base_salary), 0) * 100, 2)       as overtime_pct_of_base
from employees
group by 1, 2, 3, 4
having sum(overtime) > 0
order by total_overtime desc
    )

/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.elvis.mart_overtime_analysis", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T21:49:33.389841359+00:00
-- finished_at: 2026-03-20T21:49:36.122638325+00:00
-- elapsed: 2.7s
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.mart_city_payroll_vs_inspection_compliance
-- query_id: 01c3299d-0308-2621-0023-c5530005b726
-- desc: execute adapter call
create or replace transient  table PC_DBT_DB.dbt_EAppel.mart_city_payroll_vs_inspection_compliance
    
    
    
    as (

-- Note: SNHD is a county agency, not a city agency, so restaurant inspectors
-- do not appear in city payroll data. This mart shows city-wide staffing and
-- payroll trends alongside SNHD inspection volume and compliance rates by year,
-- useful for understanding the broader public-sector context.

with city_payroll as (
    select
        fiscal_year,
        count(*)                                as headcount,
        round(sum(gross_wages), 2)             as total_payroll,
        round(avg(base_salary), 2)             as avg_base_salary
    from PC_DBT_DB.dbt_EAppel.stg_employee_compensation
    group by 1
),

restaurant_inspections as (
    select
        year(inspection_date)                   as fiscal_year,
        count(*)                                as inspection_count,
        round(
            sum(case when inspection_result = 'Compliant' then 1 else 0 end)
            / nullif(count(*), 0) * 100, 1
        )                                       as compliance_rate_pct,
        round(avg(inspection_demerits), 2)     as avg_demerits
    from PC_DBT_DB.dbt_EAppel.stg_snhd_inspections
    where inspection_date is not null
    group by 1
)

select
    coalesce(p.fiscal_year, r.fiscal_year)  as fiscal_year,
    p.headcount                              as city_headcount,
    p.total_payroll                          as city_total_payroll,
    p.avg_base_salary                        as city_avg_base_salary,
    r.inspection_count,
    r.compliance_rate_pct,
    r.avg_demerits
from city_payroll p
full outer join restaurant_inspections r
    on p.fiscal_year = r.fiscal_year
order by fiscal_year
    )

/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.elvis.mart_city_payroll_vs_inspection_compliance", "profile_name": "user", "target_name": "default"} */;

============================== 784e72e9-81f6-499e-8023-6ed3a99893a9 ==============================
-- created_at: 2026-03-20T21:55:31.109431002+00:00
-- finished_at: 2026-03-20T21:55:31.255431891+00:00
-- elapsed: 146ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c329a3-0308-2a3c-0023-c553000610ce
-- desc: Get table schema
describe table "PC_DBT_DB"."DBT_EAPPEL"."STG_EMPLOYEE_COMPENSATION";
-- created_at: 2026-03-20T21:55:31.130413261+00:00
-- finished_at: 2026-03-20T21:55:31.278021144+00:00
-- elapsed: 147ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c329a3-0308-2a37-0023-c5530005c476
-- desc: Get table schema
describe table "PC_DBT_DB"."RAW"."FIRE_PREVENTION_INSPECTIONS";
-- created_at: 2026-03-20T21:55:32.137191127+00:00
-- finished_at: 2026-03-20T21:55:32.301746684+00:00
-- elapsed: 164ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c329a3-0308-29ec-0023-c55300058c02
-- desc: execute adapter call
show terse schemas in database PC_DBT_DB
    limit 10000
/* {"app": "dbt", "connection_name": "", "dbt_version": "2.0.0", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T21:55:32.804034961+00:00
-- finished_at: 2026-03-20T21:55:33.017310896+00:00
-- elapsed: 213ms
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.stg_fire_prevention_inspections
-- query_id: 01c329a3-0308-26c9-0023-c55300057bd6
-- desc: get_relation > list_relations call
SHOW OBJECTS IN SCHEMA "PC_DBT_DB"."DBT_EAPPEL" LIMIT 10000;
-- created_at: 2026-03-20T21:55:33.019757216+00:00
-- finished_at: 2026-03-20T21:55:33.495997674+00:00
-- elapsed: 476ms
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.stg_fire_prevention_inspections
-- query_id: 01c329a3-0308-28d7-0023-c5530005e566
-- desc: execute adapter call
create or replace   view PC_DBT_DB.dbt_EAppel.stg_fire_prevention_inspections
  
  
  
  
  as (
    with source as (
    select * from PC_DBT_DB.RAW.fire_prevention_inspections
),

renamed as (
    select
        objectid,
        name                                                    as property_name,
        address,
        city,
        state,
        zip,
        try_to_date(left(i_moyr, 10))                          as inspection_month,
        i_fy::integer                                          as fiscal_year,
        imps::integer                                          as inspections_conducted,
        no_of_units::integer                                   as unit_count,
        try_to_date(left(last_inspected, 10))                  as last_inspected_date,
        try_to_number(no_violations_written)                   as violations_written,
        try_to_number(no_dwellings_insp_mtd)                   as dwellings_inspected_mtd,
        try_to_number(no_dwellings_insp_cumulative)            as dwellings_inspected_cumulative,
        try_to_number(no_dwellings_viol_written)               as dwellings_with_violations,
        try_to_number(pcnt_dwellings_violations)               as pct_dwellings_with_violations,
        location
    from source
)

select * from renamed
  )
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.elvis.stg_fire_prevention_inspections", "profile_name": "user", "target_name": "default"} */;
-- created_at: 2026-03-20T21:55:33.500209755+00:00
-- finished_at: 2026-03-20T21:55:36.527029313+00:00
-- elapsed: 3.0s
-- outcome: success
-- dialect: snowflake
-- node_id: model.elvis.mart_fire_dept_staffing_vs_inspections
-- query_id: 01c329a3-0308-29ec-0023-c55300058c06
-- desc: execute adapter call
create or replace transient  table PC_DBT_DB.dbt_EAppel.mart_fire_dept_staffing_vs_inspections
    
    
    
    as (

with fire_employees as (
    select
        fiscal_year,
        count(*)                            as headcount,
        round(sum(gross_wages), 2)         as total_payroll,
        round(avg(base_salary), 2)         as avg_base_salary,
        round(sum(overtime), 2)            as total_overtime
    from PC_DBT_DB.dbt_EAppel.stg_employee_compensation
    where dept_code = 'FR'
    group by 1
),

fire_inspections as (
    select
        fiscal_year,
        count(*)                            as property_inspection_periods,
        sum(inspections_conducted)          as total_inspections_conducted,
        sum(violations_written)             as total_violations_written,
        sum(unit_count)                     as total_units_in_scope,
        round(avg(pct_dwellings_with_violations), 2) as avg_pct_units_with_violations
    from PC_DBT_DB.dbt_EAppel.stg_fire_prevention_inspections
    group by 1
)

select
    coalesce(e.fiscal_year, i.fiscal_year)  as fiscal_year,
    e.headcount,
    e.total_payroll,
    e.avg_base_salary,
    e.total_overtime,
    i.property_inspection_periods,
    i.total_inspections_conducted,
    i.total_violations_written,
    i.total_units_in_scope,
    i.avg_pct_units_with_violations
from fire_employees e
full outer join fire_inspections i
    on e.fiscal_year = i.fiscal_year
order by fiscal_year
    )

/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.elvis.mart_fire_dept_staffing_vs_inspections", "profile_name": "user", "target_name": "default"} */;

