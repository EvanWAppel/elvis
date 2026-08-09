{{ config(materialized='table') }}

-- Daily air quality for the county: the worst (max) AQI across monitoring sites
-- is the standard way to report a day's air quality, plus the average concentration.

with obs as (
    select * from {{ ref('stg_air_quality') }}
    where aqi is not null
)

select
    observed_date,
    parameter,
    max(aqi)                    as max_aqi,
    round(avg(concentration), 2) as avg_concentration
from obs
group by 1, 2
order by 1, 2
