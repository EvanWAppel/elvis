with source as (
    select * from {{ ref('violation_codes') }}
),

renamed as (
    select
        violation_id,
        violation_code,
        violation_demerits,
        violation_description,
        objectid
    from source
)

select * from renamed
