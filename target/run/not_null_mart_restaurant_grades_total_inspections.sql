
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select total_inspections
from PC_DBT_DB.dbt_EAppel.mart_restaurant_grades
where total_inspections is null



  
  
      
    ) dbt_internal_test