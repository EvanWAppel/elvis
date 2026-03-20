{{ config(materialized='table') }}

with inspections as (
    select * from {{ ref('stg_snhd_inspections') }}
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
