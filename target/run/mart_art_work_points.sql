
  
    



create or replace transient  table PC_DBT_DB.dbt_EAppel.mart_art_work_points
    
    
    
    as (

with artworks as (
    select * from PC_DBT_DB.dbt_EAppel.stg_art_work_points
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
    )
;




  