{{ config(materialized='table') }}

-- One row per permit (restaurant) summarizing its inspection history.
-- The public SNHD open-data export nulls out restaurant_name / address /
-- current_grade, so this mart is keyed on permit_number and derives the
-- latest grade from the populated per-inspection `inspection_grade` field
-- rather than the (null) `current_grade` column.

with inspections as (
    select * from {{ ref('stg_snhd_inspections') }}
    where inspection_date is not null
),

latest_grade as (
    select
        permit_number,
        inspection_grade as latest_grade,
        inspection_date  as latest_inspection_date,
        row_number() over (
            partition by permit_number
            order by inspection_date desc
        ) as rn
    from inspections
),

history as (
    select
        permit_number,
        count(*)                           as total_inspections,
        round(avg(inspection_demerits), 1) as avg_demerits,
        min(inspection_date)               as first_inspection,
        max(inspection_date)               as last_inspection,
        sum(case when inspection_result = 'Compliant' then 1 else 0 end)  as compliant_count,
        sum(case when inspection_result != 'Compliant' then 1 else 0 end) as non_compliant_count
    from inspections
    group by permit_number
)

select
    h.permit_number,
    g.latest_grade,
    g.latest_inspection_date,
    h.total_inspections,
    h.avg_demerits,
    h.first_inspection,
    h.last_inspection,
    h.compliant_count,
    h.non_compliant_count,
    round(h.compliant_count / nullif(h.total_inspections, 0) * 100, 1) as compliance_rate_pct
from history h
join latest_grade g on h.permit_number = g.permit_number and g.rn = 1
