with source as (
    select * from {{ source('raw', 'employee_compensation') }}
),

renamed as (
    select
        objectid,
        person_name,
        organization,
        split_part(organization, ' - ', 1)  as dept_code,
        job,
        work_group,
        left(year_ending, 4)::integer        as fiscal_year,
        gross_wages,
        base_salary,
        longevity_pay,
        overtime,
        other,
        annual_buybacks,
        pers_contributions,
        er_paid
    from source
)

select * from renamed
