select artwork_id, jurisdiction, artwork_name, artist,
       cast(medium as varchar) as medium,
       location_detail, cast(address as varchar) as address,
       cast(ward as varchar) as ward,
       try_cast(latitude as double) as latitude,
       try_cast(longitude as double) as longitude,
       cast(pic_url as varchar) as pic_url,
       cast(thumb_url as varchar) as thumb_url, source_url
from {{ source('raw', 'henderson_art') }}
