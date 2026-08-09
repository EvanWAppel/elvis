with source as (
    select * from {{ source('raw', 'snhd_violations') }}
)

select
    violation_code,
    try_cast(violation_demerits as integer) as violation_demerits,
    violation_description
from source
