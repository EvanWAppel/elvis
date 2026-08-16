{{ config(materialized='table') }}

with calls as (
    select * from {{ ref('stg_crime_calls') }}
    where incident_date is not null
)

select
    date_trunc('month', incident_date) as incident_month,
    count(*)                           as incident_count,
    count(distinct incident_type)      as distinct_types
from calls
group by 1
order by 1
