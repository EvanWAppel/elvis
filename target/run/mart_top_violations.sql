
  
    



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
;




  