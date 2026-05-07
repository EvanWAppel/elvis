{{ config(materialized='table') }}

with fire_employees as (
    select
        fiscal_year,
        count(*)                            as headcount,
        round(sum(gross_wages), 2)         as total_payroll,
        round(avg(base_salary), 2)         as avg_base_salary,
        round(sum(overtime), 2)            as total_overtime
    from {{ ref('stg_employee_compensation') }}
    where dept_code = 'FR'
    group by 1
),

fire_inspections as (
    select
        fiscal_year,
        count(*)                            as property_inspection_periods,
        sum(inspections_conducted)          as total_inspections_conducted,
        sum(violations_written)             as total_violations_written,
        sum(unit_count)                     as total_units_in_scope,
        round(avg(pct_dwellings_with_violations), 2) as avg_pct_units_with_violations
    from {{ ref('stg_fire_prevention_inspections') }}
    group by 1
)

select
    coalesce(e.fiscal_year, i.fiscal_year)  as fiscal_year,
    e.headcount,
    e.total_payroll,
    e.avg_base_salary,
    e.total_overtime,
    i.property_inspection_periods,
    i.total_inspections_conducted,
    i.total_violations_written,
    i.total_units_in_scope,
    i.avg_pct_units_with_violations
from fire_employees e
full outer join fire_inspections i
    on e.fiscal_year = i.fiscal_year
order by fiscal_year
