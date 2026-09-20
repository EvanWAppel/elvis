-- Metro-wide short-term rentals (Las Vegas, North Las Vegas, Henderson),
-- harmonized to a common shape by the loader.

with source as (
    select * from {{ source('raw', 'short_term_rentals') }}
)

select
    -- All-null feed fields may be inferred as integers by the loader.
    -- Preserve the text schema even when a jurisdiction supplies no values.
    cast(jurisdiction as varchar)  as jurisdiction,
    cast(business_name as varchar) as business_name,
    cast(status as varchar)        as status,
    cast(category as varchar)      as category,
    cast(address as varchar)       as address,
    try_cast(issued_date as date)  as issued_date,
    try_cast(latitude as double)   as latitude,
    try_cast(longitude as double)  as longitude
from source
