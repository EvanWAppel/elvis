{{ config(materialized='table') }}

-- Note: SNHD is a county agency, not a city agency, so restaurant inspectors
-- do not appear in city payroll data. This mart shows city-wide staffing and
-- payroll trends alongside SNHD inspection volume and compliance rates by year,
-- useful for understanding the broader public-sector context.

with city_payroll as (
    select
        fiscal_year,
        count(*)                                as headcount,
        round(sum(gross_wages), 2)             as total_payroll,
        round(avg(base_salary), 2)             as avg_base_salary
    from {{ ref('stg_employee_compensation') }}
    group by 1
),

restaurant_inspections as (
    select
        year(inspection_date)                   as fiscal_year,
        count(*)                                as inspection_count,
        round(
            sum(case when inspection_result = 'Compliant' then 1 else 0 end)
            / nullif(count(*), 0) * 100, 1
        )                                       as compliance_rate_pct,
        round(avg(inspection_demerits), 2)     as avg_demerits
    from {{ ref('stg_snhd_inspections') }}
    where inspection_date is not null
    group by 1
)

select
    coalesce(p.fiscal_year, r.fiscal_year)  as fiscal_year,
    p.headcount                              as city_headcount,
    p.total_payroll                          as city_total_payroll,
    p.avg_base_salary                        as city_avg_base_salary,
    r.inspection_count,
    r.compliance_rate_pct,
    r.avg_demerits
from city_payroll p
full outer join restaurant_inspections r
    on p.fiscal_year = r.fiscal_year
order by fiscal_year
