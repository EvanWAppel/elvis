{{ config(materialized='table') }}

with inspections as (
    select * from {{ ref('stg_fire_prevention_inspections') }}
    where inspection_month is not null
      -- The source injects "Monthly Total" summary rows (null address) that
      -- are period aggregates, not real properties. Keep only actual buildings.
      and address is not null
      and property_name <> 'Monthly Total'
)

select
    property_name,
    address,
    city,
    zip,
    unit_count,
    any_value(latitude)                                 as latitude,
    any_value(longitude)                                as longitude,
    count(*)                                            as inspection_count,
    max(last_inspected_date)                            as most_recent_inspection,
    sum(violations_written)                             as total_violations,
    round(avg(violations_written), 2)                  as avg_violations_per_period,
    round(avg(pct_dwellings_with_violations), 1)       as avg_pct_dwellings_with_violations,
    min(fiscal_year)                                    as first_fiscal_year,
    max(fiscal_year)                                    as last_fiscal_year
from inspections
group by 1, 2, 3, 4, 5
order by total_violations desc
