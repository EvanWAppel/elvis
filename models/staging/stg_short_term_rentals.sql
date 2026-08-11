-- Metro-wide short-term rentals (Las Vegas, North Las Vegas, Henderson),
-- harmonized to a common shape by the loader.

with source as (
    select * from {{ source('raw', 'short_term_rentals') }}
)

select
    jurisdiction,
    business_name,
    status,
    category,
    address,
    try_cast(issued_date as date)  as issued_date,
    try_cast(latitude as double)   as latitude,
    try_cast(longitude as double)  as longitude
from source
