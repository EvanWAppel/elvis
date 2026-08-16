{{ config(materialized='table') }}

-- Monthly Lake Mead elevation. The long decline (and the "bathtub ring") is the
-- story; a monthly average smooths the daily noise.

with readings as (
    select * from {{ ref('stg_lake_mead') }}
)

select
    date_trunc('month', reading_date) as reading_month,
    round(avg(elevation_ft), 2)       as avg_elevation_ft,
    round(min(elevation_ft), 2)       as min_elevation_ft,
    round(max(elevation_ft), 2)       as max_elevation_ft
from readings
group by 1
order by 1
