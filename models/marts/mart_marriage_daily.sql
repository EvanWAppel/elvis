{{ config(materialized='table') }}

-- Daily license counts, for spotting the famous spikes (Valentine's Day, New
-- Year's Eve, and novelty dates like 07/07/07 and 12/12/12).

with licenses as (
    select * from {{ ref('stg_marriage_licenses') }}
    where license_date is not null
)

select
    license_date,
    month(license_date)  as month_of_year,
    day(license_date)    as day_of_month,
    count(*)             as license_count
from licenses
group by 1, 2, 3
order by 1
