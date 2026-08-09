{{ config(materialized='table') }}

-- Hour-of-day x weekday grid for a calls-for-service heatmap.

with calls as (
    select * from {{ ref('stg_crime_calls') }}
    where hour_of_day is not null and weekday is not null
)

select
    weekday,
    hour_of_day,
    count(*) as incident_count
from calls
group by 1, 2
order by 1, 2
