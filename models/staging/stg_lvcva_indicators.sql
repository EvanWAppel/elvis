-- LVCVA monthly tourism / gaming / airport indicators, already melted to long
-- form (metric, month, value) by the loader.

with source as (
    select * from {{ source('raw', 'lvcva_indicators') }}
)

select
    metric,
    try_cast(month as date) as indicator_month,
    try_cast(value as double) as value
from source
where try_cast(month as date) is not null
