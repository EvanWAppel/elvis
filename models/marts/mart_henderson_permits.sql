{{ config(materialized='table') }}

-- Henderson permits per month with a case-type breakdown for the permits page.

with permits as (
    select * from {{ ref('stg_henderson_permits') }}
    where issue_date is not null
)

select
    date_trunc('month', issue_date) as issue_month,
    coalesce(case_type, 'Unknown')  as case_type,
    count(*)                        as permit_count
from permits
group by 1, 2
order by 1, 2
