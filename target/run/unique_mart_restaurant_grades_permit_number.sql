
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    permit_number as unique_field,
    count(*) as n_records

from PC_DBT_DB.dbt_EAppel.mart_restaurant_grades
where permit_number is not null
group by permit_number
having count(*) > 1



  
  
      
    ) dbt_internal_test