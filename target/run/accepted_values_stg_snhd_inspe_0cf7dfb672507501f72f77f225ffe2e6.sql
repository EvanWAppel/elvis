
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        inspection_result as value_field,
        count(*) as n_records

    from PC_DBT_DB.dbt_EAppel.stg_snhd_inspections
    group by inspection_result

)

select *
from all_values
where value_field not in (
    'Compliant','Non-Compliant','Corrected On-Site','Out of Business','"B" Downgrade','"C" Downgrade','Closed','Voluntary Closure'
)



  
  
      
    ) dbt_internal_test