with source as (
    select * from {{ source('raw', 'road_construction') }}
)

select
    source                        as data_source,
    project_name,
    description,
    status,
    category,
    road_name,
    extent,
    try_cast(start_date as date)  as start_date,
    try_cast(end_date as date)    as end_date,
    contractor,
    is_full_closure,
    url,
    path_json,                    -- JSON [[lon, lat], ...] for the deck.gl PathLayer
    try_cast(latitude as double)  as latitude,
    try_cast(longitude as double) as longitude
from source
where latitude is not null and longitude is not null
