-- EPA AQS daily air-quality summaries for Clark County (one row per monitoring
-- site, parameter, and day).

with source as (
    select * from {{ source('raw', 'air_quality') }}
)

select
    parameter,
    try_cast(date_local as date)         as observed_date,
    try_cast(arithmetic_mean as double)  as concentration,
    try_cast(aqi as integer)             as aqi,
    local_site_name                      as site
from source
where try_cast(date_local as date) is not null
