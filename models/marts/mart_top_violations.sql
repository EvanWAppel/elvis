{{ config(materialized='table') }}

with inspections as (
    select * from {{ ref('stg_snhd_inspections') }}
    where violation_codes is not null
      and violation_codes != ''
      and inspection_date is not null
),

flattened as (
    select
        category_name,
        inspection_type,
        inspection_grade,
        inspection_date,
        trim(unnest(string_split(violation_codes, '|'))) as violation_code
    from inspections
),

codes as (
    select * from {{ ref('stg_violation_codes') }}
)

select
    f.violation_code,
    c.violation_description,
    c.violation_demerits,
    f.category_name,
    f.inspection_type,
    count(*) as occurrence_count
from flattened f
left join codes c on f.violation_code = cast(c.violation_code as varchar)
where f.violation_code != ''
group by 1, 2, 3, 4, 5
order by occurrence_count desc
