-- The source DESCRIPTION is a pipe-delimited blob with a *variable* number of
-- parts: artist | medium | <one or more location parts> | Ward N. The ward is
-- sometimes absent (UNLV campus / county pieces) and its typo variants
-- ("Ward 5 (CLV Collection", "Colllection") mean a fixed split_part(..., 5)
-- both misses it and produces dirty values. Instead we explode the field,
-- locate the "Ward N" token wherever it lands, and rebuild the columns around
-- it. This mirrors build_snapshot.py, which powers the public Streamlit demo.

with source as (
    select * from {{ source('raw', 'art_work_points') }}
),

-- One trimmed part per row, keeping its position within the description.
parts as (
    select
        s.objectid,
        f.index                                                   as part_index,
        trim(f.value::string)                                     as part,
        regexp_substr(trim(f.value::string), 'Ward\\s+\\d+', 1, 1, 'i')
            is not null                                           as is_ward
    from source s,
         lateral flatten(input => split(s.description, '|')) f
    where trim(f.value::string) <> ''
),

-- Position of the ward token per artwork (null when the piece has no ward).
ward_index as (
    select objectid, max(part_index) as ward_pos
    from parts
    where is_ward
    group by objectid
),

fields as (
    select
        p.objectid,
        max(case when p.part_index = 0 then p.part end)           as artist,
        max(case when p.part_index = 1 then p.part end)           as medium,
        max(case when p.part_index = 2 then p.part end)           as location_detail,
        -- Everything after location_detail and before the ward, space-joined.
        listagg(
            case
                when p.part_index >= 3
                     and (wi.ward_pos is null or p.part_index < wi.ward_pos)
                then p.part
            end,
            ' '
        ) within group (order by p.part_index)                    as address,
        -- Normalize the matched token to a clean "Ward N".
        max(
            case when p.is_ward
                then 'Ward ' || regexp_substr(p.part, 'Ward\\s+(\\d+)', 1, 1, 'ie', 1)
            end
        )                                                          as ward
    from parts p
    left join ward_index wi on p.objectid = wi.objectid
    group by p.objectid
),

renamed as (
    select
        s.objectid,
        s.name              as artwork_name,
        f.artist,
        f.medium,
        f.location_detail,
        f.address,
        f.ward,
        s.description       as full_description,
        s.pic_url,
        s.thumb_url,
        s.icon_color,
        s.lat_1::float      as latitude,
        s.long::float       as longitude
    from source s
    join fields f on s.objectid = f.objectid
)

select * from renamed
