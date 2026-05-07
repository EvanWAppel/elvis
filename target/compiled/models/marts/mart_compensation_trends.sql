

with employees as (
    select * from PC_DBT_DB.dbt_EAppel.stg_employee_compensation
)

select
    fiscal_year,
    count(*)                                                            as headcount,
    count(distinct organization)                                        as org_count,
    round(sum(gross_wages), 2)                                         as total_payroll,
    round(avg(gross_wages), 2)                                         as avg_gross_wages,
    round(avg(base_salary), 2)                                         as avg_base_salary,
    round(sum(overtime), 2)                                            as total_overtime,
    round(sum(overtime) / nullif(sum(gross_wages), 0) * 100, 2)       as overtime_pct_of_payroll,
    round(sum(pers_contributions), 2)                                  as total_pers_contributions,
    round(sum(longevity_pay), 2)                                       as total_longevity_pay
from employees
group by 1
order by 1