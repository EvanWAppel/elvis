
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select serial_number
from PC_DBT_DB.dbt_EAppel.stg_snhd_inspections
where serial_number is null



  
  
      
    ) dbt_internal_test