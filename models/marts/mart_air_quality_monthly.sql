{{ config(materialized='table') }}

with daily as (
    select * from {{ ref('mart_air_quality_daily') }}
)

select
    date_trunc('month', observed_date) as observed_month,
    parameter,
    round(avg(max_aqi), 0)             as avg_aqi,
    max(max_aqi)                       as peak_aqi
from daily
group by 1, 2
order by 1, 2
