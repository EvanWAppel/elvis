{{ config(materialized='table') }}

with licenses as (
    select * from {{ ref('stg_marriage_licenses') }}
    where license_date is not null
)

select
    date_trunc('month', license_date) as license_month,
    count(*)                          as license_count
from licenses
group by 1
order by 1
