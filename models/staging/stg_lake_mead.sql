-- Daily Lake Mead elevation (feet above sea level) from USBR RISE.

with source as (
    select * from {{ source('raw', 'lake_mead') }}
)

select
    try_cast(datetime_utc as timestamp)::date as reading_date,
    try_cast(elevation_ft as double)          as elevation_ft
from source
where try_cast(elevation_ft as double) is not null
