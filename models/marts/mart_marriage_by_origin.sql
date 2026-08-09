{{ config(materialized='table') }}

-- Where couples getting married in Clark County mail from. US couples carry a
-- MailingState; international couples fall back to their country.

with licenses as (
    select * from {{ ref('stg_marriage_licenses') }}
)

select
    coalesce(
        case when mailing_country in ('UNITED STATES', 'USA', 'US')
             then mailing_state end,
        mailing_country,
        'UNKNOWN'
    )               as origin,
    count(*)        as license_count
from licenses
group by 1
order by license_count desc
