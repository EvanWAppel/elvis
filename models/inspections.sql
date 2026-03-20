 select *                                                                               
  from {{ source('raw', 'snhd_inspections') }}                                           
  where inspection_result is not null   