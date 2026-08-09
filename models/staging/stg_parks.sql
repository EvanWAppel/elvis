-- City of Las Vegas parks. Polygon centroids are reprojected to WGS84
-- (longitude/latitude) at fetch time for point mapping.

with source as (
    select * from {{ source('raw', 'parks') }}
),

renamed as (
    select
        "NAME"                          as park_name,
        "ADDRESS"                       as address,
        "STATUS"                        as status,
        "PUB_ACCESS"                    as public_access,
        "WARD"                          as ward,
        try_cast("ACRES" as double)     as acres,
        -- The five TYPE_ slots hold a park's amenity tags; coalesce the primary.
        cast("TYPE_1" as varchar)       as park_type,
        list_filter(
            [
                cast("TYPE_1" as varchar), cast("TYPE_2" as varchar),
                cast("TYPE_3" as varchar), cast("TYPE_4" as varchar),
                cast("TYPE_5" as varchar)
            ],
            x -> x is not null and x <> ''
        )                               as park_types,
        try_cast(latitude as double)    as latitude,
        try_cast(longitude as double)   as longitude
    from source
)

select
    park_name,
    address,
    status,
    public_access,
    case when ward is not null and ward <> '' then 'Ward ' || ward end as ward,
    acres,
    park_type,
    array_to_string(park_types, ', ') as amenities,
    latitude,
    longitude
from renamed
