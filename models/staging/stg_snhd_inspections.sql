with source as (
    select * from {{ source('raw', 'snhd_inspections') }}
),

types as (
    select * from {{ source('raw', 'snhd_inspection_types') }}
),

renamed as (
    select
        s.serial_number,
        s.permit_number,
        s.facility_id,
        try_cast(s.inspection_date as timestamp)::date  as inspection_date,
        s.inspection_time,
        s.employee_id,
        coalesce(t.inspection_type, s.inspection_type_id) as inspection_type,
        try_cast(s.inspection_demerits as integer)      as inspection_demerits,
        s.inspection_grade,
        s.permit_status,
        s.inspection_result,
        -- SNHD's passing state is an "A" grade in this era (the pre-2016
        -- "Compliant" label is kept for forward-compatibility). Normalize the
        -- result vocabulary into stable flags for downstream marts.
        (s.inspection_result in ('Compliant', '"A" Grade'))       as is_compliant,
        (s.inspection_result in ('"B" Downgrade', '"C" Downgrade', 'Non-compliant'))
                                                                  as is_downgrade,
        (s.inspection_result in (
            'Closed with Fees', 'Closed without Fees',
            'Cease and Desist', 'Permit Suspended'
        ))                                                        as is_closure,
        s.violations                                    as violation_codes,
        case
            when s.violations is null or s.violations = '' then 0
            else len(string_split(s.violations, ','))
        end                                             as violation_count,
        try_cast(s.record_updated as timestamp)         as record_updated
    from source s
    left join types t on s.inspection_type_id = t.inspection_type_id
)

select * from renamed
