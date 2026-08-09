{{ config(materialized='table') }}

with strs as (
    select * from {{ ref('stg_short_term_rentals') }}
)

select
    license_no,
    business_name,
    business_type,
    category,
    license_status,
    address,
    issued_date,
    expires_date,
    latitude,
    longitude
from strs
where latitude is not null and longitude is not null
order by business_name
