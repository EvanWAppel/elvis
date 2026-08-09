with source as (
    select * from {{ source('raw', 'snhd_establishments') }}
)

select
    permit_number,
    restaurant_name,
    location_name,
    address,
    city_name,
    zip_code,
    -- The source swaps the two: its `latitude` column holds the longitude
    -- (~-115 for Las Vegas) and its `longitude` column holds the latitude
    -- (~36). Swap them back so downstream mapping is correct.
    try_cast(longitude as double)             as latitude,
    try_cast(latitude as double)              as longitude,
    nullif(current_grade, '')                 as current_grade,
    try_cast(current_demerits as integer)     as current_demerits,
    try_cast(date_current as timestamp)::date as date_current,
    nullif(previous_grade, '')                as previous_grade,
    record_status,
    case record_status
        when '01' then 'Active'
        when '02' then 'Inactive'
        when '03' then 'Temporarily inactive'
        when '04' then 'Active (billing-exempt)'
        when '05' then 'Inactive (billable)'
        else record_status
    end                                       as status
from source
