{{ config(materialized='table') }}

with artworks as (
    select * from {{ ref('stg_art_work_points') }}
)

select
    objectid,
    artwork_name,
    artist,
    medium,
    location_detail,
    address,
    ward,
    latitude,
    longitude,
    pic_url,
    thumb_url
from artworks
order by ward, artwork_name
