with source as (
    select * from {{ source('raw', 'fire_prevention_inspections') }}
),

renamed as (
    select
        objectid,
        name                                            as property_name,
        address,
        city,
        state,
        zip,
        try_cast(i_moyr as timestamp)::date             as inspection_month,
        try_cast(i_fy as integer)                       as fiscal_year,
        try_cast(imps as integer)                       as inspections_conducted,
        try_cast(no_of_units as integer)                as unit_count,
        try_cast(last_inspected as timestamp)::date     as last_inspected_date,
        try_cast(no_violations_written as double)       as violations_written,
        try_cast(no_dwellings_insp_mtd as double)       as dwellings_inspected_mtd,
        try_cast(no_dwellings_insp_cumulative as double) as dwellings_inspected_cumulative,
        try_cast(no_dwellings_viol_written as double)   as dwellings_with_violations,
        try_cast(pcnt_dwellings_violations as double)   as pct_dwellings_with_violations,
        location
    from source
)

select * from renamed
