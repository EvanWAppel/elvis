with source as (
    select * from PC_DBT_DB.RAW.snhd_inspections
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
        current_demerits::integer    as current_demerits,
        current_grade,
        try_to_date(date_current)    as date_current,
        try_to_date(inspection_date) as inspection_date,
        inspection_time,
        employee_id,
        inspection_type,
        inspection_demerits::integer as inspection_demerits,
        inspection_grade,
        permit_status,
        inspection_result,
        violations                   as violation_codes,
        case
            when violations is null or violations = '' then 0
            else array_size(split(violations, '|'))
        end                          as violation_count,
        try_to_timestamp(record_updated) as record_updated,
        objectid
    from source
)

select * from renamed