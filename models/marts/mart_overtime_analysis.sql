{{ config(materialized='table') }}

with employees as (
    select * from {{ ref('stg_employee_compensation') }}
)

select
    organization,
    dept_code,
    work_group,
    fiscal_year,
    count(*)                                                            as headcount,
    count(case when overtime > 0 then 1 end)                          as employees_with_overtime,
    round(sum(overtime), 2)                                            as total_overtime,
    round(avg(case when overtime > 0 then overtime end), 2)           as avg_overtime_per_earner,
    round(sum(base_salary), 2)                                         as total_base_salary,
    round(sum(overtime) / nullif(sum(base_salary), 0) * 100, 2)       as overtime_pct_of_base
from employees
group by 1, 2, 3, 4
having sum(overtime) > 0
order by total_overtime desc
