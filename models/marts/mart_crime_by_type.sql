{{ config(materialized='table') }}

with calls as (
    select * from {{ ref('stg_crime_calls') }}
)

select
    classification,
    incident_type,
    count(*) as incident_count
from calls
group by 1, 2
order by incident_count desc
