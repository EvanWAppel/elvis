-- City of Henderson building permits (issue date + case type; no valuation).

with source as (
    select * from {{ source('raw', 'henderson_permits') }}
)

select
    case_type,
    status,
    try_cast(issue_date as date) as issue_date,
    description,
    address
from source
