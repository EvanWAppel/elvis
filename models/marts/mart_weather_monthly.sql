{{ config(materialized='table') }}

with obs as (
    select * from {{ ref('stg_weather') }}
)

select
    date_trunc('month', observed_date) as observed_month,
    round(avg(tmax_f), 1)              as avg_high_f,
    round(avg(tmin_f), 1)              as avg_low_f,
    max(tmax_f)                        as record_high_f,
    min(tmin_f)                        as record_low_f
from obs
group by 1
order by 1
