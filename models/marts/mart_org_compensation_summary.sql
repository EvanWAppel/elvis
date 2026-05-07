{{ config(materialized='table') }}

with employees as (
    select * from {{ ref('stg_employee_compensation') }}
)

select
    organization,
    dept_code,
    fiscal_year,
    count(*)                                                            as headcount,
    sum(gross_wages)                                                    as total_gross_wages,
    round(avg(base_salary), 2)                                         as avg_base_salary,
    min(base_salary)                                                    as min_base_salary,
    max(base_salary)                                                    as max_base_salary,
    sum(overtime)                                                       as total_overtime,
    round(sum(overtime) / nullif(sum(gross_wages), 0) * 100, 2)       as overtime_pct_of_payroll,
    sum(pers_contributions)                                             as total_pers_contributions
from employees
group by 1, 2, 3
order by organization, fiscal_year
