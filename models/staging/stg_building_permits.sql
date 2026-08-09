-- City of Las Vegas building permits (archived permit history with valuations).

with source as (
    select * from {{ source('raw', 'building_permits') }}
)

select
    try_cast("Application_Number" as bigint) as application_number,
    "Application_Type"                       as application_type,
    "Work_Type"                              as work_type,
    "Applicant"                              as applicant,
    try_cast("Valuation" as double)          as valuation,
    try_cast("Issue_Date" as timestamp)::date as issue_date,
    "Location"                               as location
from source
