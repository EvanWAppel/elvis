with source as (
    select * from PC_DBT_DB.RAW.fire_prevention_inspections
),

renamed as (
    select
        objectid,
        name                                                    as property_name,
        address,
        city,
        state,
        zip,
        try_to_date(left(i_moyr, 10))                          as inspection_month,
        i_fy::integer                                          as fiscal_year,
        imps::integer                                          as inspections_conducted,
        no_of_units::integer                                   as unit_count,
        try_to_date(left(last_inspected, 10))                  as last_inspected_date,
        try_to_number(no_violations_written)                   as violations_written,
        try_to_number(no_dwellings_insp_mtd)                   as dwellings_inspected_mtd,
        try_to_number(no_dwellings_insp_cumulative)            as dwellings_inspected_cumulative,
        try_to_number(no_dwellings_viol_written)               as dwellings_with_violations,
        try_to_number(pcnt_dwellings_violations)               as pct_dwellings_with_violations,
        location
    from source
)

select * from renamed