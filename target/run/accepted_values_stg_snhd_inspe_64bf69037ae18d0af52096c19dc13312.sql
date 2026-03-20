
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        inspection_grade as value_field,
        count(*) as n_records

    from PC_DBT_DB.dbt_EAppel.stg_snhd_inspections
    group by inspection_grade

)

select *
from all_values
where value_field not in (
    'A','B','C',''
)



  
  
      
    ) dbt_internal_test