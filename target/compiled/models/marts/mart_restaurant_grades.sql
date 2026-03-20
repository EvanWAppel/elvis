

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