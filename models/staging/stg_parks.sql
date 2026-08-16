-- Metro-wide parks (Las Vegas, Henderson, unincorporated Clark County, North
-- Las Vegas). has_water is true/false where a jurisdiction publishes water-feature
-- data (Las Vegas via spatial join, Henderson natively) and null otherwise.

with source as (
    select * from {{ source('raw', 'parks') }}
)

select
    jurisdiction,
    park_name,
    address,
    try_cast(acres as double)     as acres,
    cast(has_water as boolean)    as has_water,
    try_cast(latitude as double)  as latitude,
    try_cast(longitude as double) as longitude
from source
where park_name is not null
