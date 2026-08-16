-- TEMPORARILY DISABLED with its source (see stg_business_licenses); re-enable by
-- restoring enabled=true when the CLV Business Licenses feed recovers.
{{ config(materialized='table', enabled=false) }}

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
