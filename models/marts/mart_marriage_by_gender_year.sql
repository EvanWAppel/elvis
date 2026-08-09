{{ config(materialized='table') }}

-- Same-sex vs different-sex licenses per year. Nevada began issuing same-sex
-- marriage licenses in October 2014, which shows up clearly here.

with licenses as (
    select * from {{ ref('stg_marriage_licenses') }}
    where license_date is not null
      and party1_gender is not null
      and party2_gender is not null
)

select
    year(license_date) as license_year,
    case when party1_gender = party2_gender then 'Same-sex' else 'Different-sex' end
                       as couple_type,
    count(*)           as license_count
from licenses
group by 1, 2
order by 1, 2
