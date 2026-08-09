{{ config(materialized='table') }}

-- One row per inspection, keyed on permit_number for per-restaurant drill-down.

select
    permit_number,
    serial_number,
    inspection_date,
    inspection_type,
    inspection_grade,
    inspection_result,
    inspection_demerits,
    violation_count
from {{ ref('stg_snhd_inspections') }}
where inspection_date is not null
