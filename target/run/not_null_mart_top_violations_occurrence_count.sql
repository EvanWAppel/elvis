
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select occurrence_count
from PC_DBT_DB.dbt_EAppel.mart_top_violations
where occurrence_count is null



  
  
      
    ) dbt_internal_test