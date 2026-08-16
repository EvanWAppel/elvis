-- LVMPD calls-for-service (recent years). Coordinates already arrive as WGS84
-- lat/long attributes; ArcGIS date fields are normalized to strings upstream.

with source as (
    select * from {{ source('raw', 'crime_calls') }}
)

select
    "IncidentNumber"                        as incident_number,
    try_cast("IncidentDate" as timestamp)   as incident_date,
    "Classification"                        as classification,
    "IncidentTypeDescription"               as incident_type,
    "Address"                               as address,
    "Disposition"                           as disposition,
    "Weekday"                               as weekday,
    try_cast("Hour" as integer)             as hour_of_day,
    try_cast("Month" as integer)            as month_of_year,
    try_cast("Year" as integer)             as year,
    "ZipCode"                               as zip_code,
    try_cast("Latitude" as double)          as latitude,
    try_cast("Longitude" as double)         as longitude
from source
