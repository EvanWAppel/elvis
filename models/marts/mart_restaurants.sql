{{ config(materialized='table') }}

-- One row per restaurant (permit), joining the SNHD establishment detail
-- (name / address / geo / current grade) to aggregated inspection history.
-- Establishments with no inspections on record keep zeroed counts.

with establishments as (
    select * from {{ ref('stg_snhd_establishments') }}
),

inspections as (
    select * from {{ ref('stg_snhd_inspections') }}
    where inspection_date is not null
),

history as (
    select
        permit_number,
        count(*)                            as total_inspections,
        round(avg(inspection_demerits), 1)  as avg_demerits,
        max(inspection_demerits)            as worst_demerits,
        min(inspection_date)                as first_inspection,
        max(inspection_date)                as last_inspection,
        sum(case when is_compliant then 1 else 0 end)      as compliant_count,
        sum(case when not is_compliant then 1 else 0 end)  as non_compliant_count,
        sum(case when is_downgrade then 1 else 0 end)      as downgrades,
        sum(case when is_closure then 1 else 0 end)        as closures,
        sum(case when is_downgrade or is_closure then 1 else 0 end) as failed_inspections,
        sum(violation_count)                as total_violations
    from inspections
    group by permit_number
)

select
    e.permit_number,
    e.restaurant_name,
    e.address,
    e.city_name,
    e.zip_code,
    e.latitude,
    e.longitude,
    e.status,
    e.current_grade,
    e.current_demerits,
    e.date_current,
    coalesce(h.total_inspections, 0)   as total_inspections,
    h.avg_demerits,
    h.worst_demerits,
    h.first_inspection,
    h.last_inspection,
    coalesce(h.compliant_count, 0)     as compliant_count,
    coalesce(h.non_compliant_count, 0) as non_compliant_count,
    coalesce(h.downgrades, 0)          as downgrades,
    coalesce(h.closures, 0)            as closures,
    coalesce(h.failed_inspections, 0)  as failed_inspections,
    coalesce(h.total_violations, 0)    as total_violations,
    round(h.compliant_count / nullif(h.total_inspections, 0) * 100, 1)    as compliance_rate_pct,
    round(h.failed_inspections / nullif(h.total_inspections, 0) * 100, 1) as failure_rate_pct
from establishments e
left join history h on e.permit_number = h.permit_number
