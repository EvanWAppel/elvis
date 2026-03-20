with source as (
    select * from {{ source('raw', 'art_work_points') }}
),

renamed as (
    select
        objectid,
        name                                as artwork_name,
        trim(split_part(description, '|', 1)) as artist,
        trim(split_part(description, '|', 2)) as medium,
        trim(split_part(description, '|', 3)) as location_detail,
        trim(split_part(description, '|', 4)) as address,
        trim(split_part(description, '|', 5)) as ward,
        description                         as full_description,
        pic_url,
        thumb_url,
        icon_color,
        lat_1::float                        as latitude,
        long::float                         as longitude
    from source
)

select * from renamed
