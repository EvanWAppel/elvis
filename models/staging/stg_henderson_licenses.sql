-- City of Henderson business licenses.

with source as (
    select * from {{ source('raw', 'henderson_licenses') }}
)

select
    business_name,
    license_type,
    status,
    try_cast(issue_date as date) as issue_date,
    address
from source
