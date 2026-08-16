{{ config(materialized='table') }}

-- Count of extreme-heat days per year — a simple, vivid climate signal for the
-- valley. Partial current-year counts are expected for the latest year.

with obs as (
    select * from {{ ref('stg_weather') }}
    where tmax_f is not null
)

select
    year(observed_date)                                as observed_year,
    sum(case when tmax_f >= 100 then 1 else 0 end)     as days_100f_plus,
    sum(case when tmax_f >= 110 then 1 else 0 end)     as days_110f_plus,
    round(avg(tmax_f), 1)                              as avg_high_f
from obs
group by 1
order by 1
