
  
    



create or replace transient  table PC_DBT_DB.dbt_EAppel.mart_job_pay_bands
    
    
    
    as (

with employees as (
    select * from PC_DBT_DB.dbt_EAppel.stg_employee_compensation
)

select
    job,
    work_group,
    fiscal_year,
    count(*)                                as headcount,
    round(min(base_salary), 2)             as min_base_salary,
    round(avg(base_salary), 2)             as avg_base_salary,
    round(max(base_salary), 2)             as max_base_salary,
    round(max(base_salary)
        - min(base_salary), 2)             as base_salary_spread,
    round(avg(gross_wages), 2)             as avg_gross_wages,
    round(avg(overtime), 2)               as avg_overtime
from employees
group by 1, 2, 3
having count(*) > 1
order by avg_base_salary desc
    )
;




  