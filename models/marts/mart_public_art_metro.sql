select
    'las_vegas:' || cast(objectid as varchar) as artwork_id,
    'Las Vegas' as jurisdiction, artwork_name, artist, medium,
    location_detail, address, ward, latitude, longitude, pic_url, thumb_url,
    null::varchar as source_url
from {{ ref('stg_art_work_points') }}
union all
select * from {{ ref('stg_henderson_art') }}
