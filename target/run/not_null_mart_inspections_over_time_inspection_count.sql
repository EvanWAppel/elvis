
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select inspection_count
from PC_DBT_DB.dbt_EAppel.mart_inspections_over_time
where inspection_count is null



  
  
      
    ) dbt_internal_test