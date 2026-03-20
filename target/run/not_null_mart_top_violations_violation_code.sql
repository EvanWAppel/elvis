
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select violation_code
from PC_DBT_DB.dbt_EAppel.mart_top_violations
where violation_code is null



  
  
      
    ) dbt_internal_test