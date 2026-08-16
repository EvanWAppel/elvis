{{ config(materialized='table') }}

with licenses as (
    select * from {{ ref('stg_business_licenses') }}
)

select
    coalesce(type_of_business, 'Unknown') as type_of_business,
    count(*)                              as license_count,
    sum(case when lower(status) = 'active' then 1 else 0 end) as active_count
from licenses
group by 1
order by license_count desc
