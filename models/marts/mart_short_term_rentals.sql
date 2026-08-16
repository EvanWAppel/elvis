{{ config(materialized='table') }}

with strs as (
    select * from {{ ref('stg_short_term_rentals') }}
)

select
    jurisdiction,
    business_name,
    status,
    category,
    address,
    issued_date,
    latitude,
    longitude
from strs
where latitude is not null and longitude is not null
order by jurisdiction, business_name
