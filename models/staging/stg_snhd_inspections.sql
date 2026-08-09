with source as (
    select * from {{ source('raw', 'snhd_inspections') }}
),

renamed as (
    select
        serial_number,
        permit_number,
        restaurant_name,
        location_name,
        category_name,
        address,
        city,
        state,
        zip,
        try_cast(current_demerits as integer)          as current_demerits,
        current_grade,
        try_cast(date_current as timestamp)::date       as date_current,
        try_cast(inspection_date as timestamp)::date    as inspection_date,
        inspection_time,
        employee_id,
        inspection_type,
        try_cast(inspection_demerits as integer)        as inspection_demerits,
        inspection_grade,
        permit_status,
        inspection_result,
        violations                                      as violation_codes,
        case
            when violations is null or violations = '' then 0
            else len(string_split(violations, '|'))
        end                                             as violation_count,
        try_cast(record_updated as timestamp)           as record_updated,
        objectid
    from source
)

select * from renamed
