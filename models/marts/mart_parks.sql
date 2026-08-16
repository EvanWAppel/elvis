{{ config(materialized='table') }}

with parks as (
    select * from {{ ref('stg_parks') }}
)

select
    jurisdiction,
    park_name,
    address,
    acres,
    has_water,
    latitude,
    longitude
from parks
where latitude is not null and longitude is not null
order by jurisdiction, park_name
