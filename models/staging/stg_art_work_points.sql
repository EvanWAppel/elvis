-- The source DESCRIPTION is a pipe-delimited blob with a *variable* number of
-- parts: artist | medium | <one or more location parts> | Ward N. The ward is
-- sometimes absent (UNLV campus / county pieces) and has typo variants
-- ("Ward 5 (CLV Collection", "Colllection"), so a fixed split position both
-- misses it and produces dirty values. Instead we split into a cleaned list,
-- locate the "Ward N" token wherever it lands, normalize it, and rebuild the
-- location_detail / address around it. Mirrors build_warehouse.py's parse.

with source as (
    select * from {{ source('raw', 'art_work_points') }}
),

parsed as (
    select
        objectid,
        name        as artwork_name,
        description as full_description,
        pic_url,
        thumb_url,
        icon_color,
        try_cast(lat_1 as double) as latitude,
        try_cast("long" as double) as longitude,

        -- Cleaned, trimmed, non-empty parts (DuckDB lists are 1-indexed).
        list_filter(
            list_transform(string_split(description, '|'), x -> trim(x)),
            x -> x <> ''
        ) as parts,

        -- 1-based index of the (last) part that contains a "Ward N" token.
        list_max(
            list_filter(
                list_transform(
                    list_filter(
                        list_transform(string_split(description, '|'), x -> trim(x)),
                        x -> x <> ''
                    ),
                    (x, i) -> case when regexp_matches(x, 'Ward\s+\d+') then i end
                ),
                x -> x is not null
            )
        ) as ward_pos,

        -- Ward number extracted from anywhere in the description.
        regexp_extract(description, 'Ward\s+(\d+)', 1) as ward_num
    from source
),

fields as (
    select
        objectid,
        artwork_name,
        full_description,
        pic_url,
        thumb_url,
        icon_color,
        latitude,
        longitude,
        parts[1] as artist,
        parts[2] as medium,
        case when ward_num <> '' then 'Ward ' || ward_num end as ward,
        -- Parts after the medium (index 3) and before the ward.
        array_slice(parts, 3, coalesce(ward_pos - 1, len(parts))) as middle
    from parsed
)

select
    objectid,
    artwork_name,
    artist,
    medium,
    middle[1] as location_detail,
    array_to_string(array_slice(middle, 2, len(middle)), ' ') as address,
    ward,
    full_description,
    pic_url,
    thumb_url,
    icon_color,
    latitude,
    longitude
from fields
