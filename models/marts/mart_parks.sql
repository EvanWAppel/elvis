{{ config(materialized='table') }}

with parks as (
    select * from {{ ref('stg_parks') }}
)

select
    park_name,
    address,
    status,
    public_access,
    ward,
    acres,
    park_type,
    amenities,
    latitude,
    longitude
from parks
where latitude is not null and longitude is not null
order by park_name
