{{ config(materialized='table') }}

with licenses as (
    select * from {{ ref('stg_henderson_licenses') }}
)

select
    coalesce(license_type, 'Unknown') as license_type,
    count(*)                          as license_count,
    sum(case when lower(status) = 'active' then 1 else 0 end) as active_count
from licenses
group by 1
order by license_count desc
