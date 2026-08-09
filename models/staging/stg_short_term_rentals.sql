-- City of Las Vegas short-term rental licenses. Point geometry is reprojected to
-- WGS84 (longitude/latitude) at fetch time.

with source as (
    select * from {{ source('raw', 'short_term_rentals') }}
)

select
    "LICENSENO"                             as license_no,
    "BUS_NAME"                              as business_name,
    "BUS_TYPE"                              as business_type,
    "LICENSECATDESC"                        as category,
    "LICSTATUS"                             as license_status,
    "ADDRESS"                               as address,
    "BUS_CITY_ST_ZIP"                       as city_state_zip,
    try_cast("ISSDTTM" as timestamp)::date  as issued_date,
    try_cast("EXPDTTM" as timestamp)::date  as expires_date,
    try_cast(latitude as double)            as latitude,
    try_cast(longitude as double)           as longitude
from source
