{{ config(materialized='table') }}

-- One row per license, lightly cleaned, for the searchable table + status/geo
-- breakdowns on the page.

with licenses as (
    select * from {{ ref('stg_business_licenses') }}
)

select
    license_no,
    business_name,
    type_of_business,
    status,
    zip_code,
    within_city_limits,
    owner
from licenses
order by business_name
