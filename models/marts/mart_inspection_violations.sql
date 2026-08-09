{{ config(materialized='table') }}

-- One row per (inspection, violation), decoding the comma-separated violation
-- codes into their descriptions and demerit weights. Keyed on serial_number
-- (the inspection) and permit_number for drill-down.

with flattened as (
    select
        serial_number,
        permit_number,
        inspection_date,
        trim(unnest(string_split(violation_codes, ','))) as violation_code
    from {{ ref('stg_snhd_inspections') }}
    where violation_codes is not null
      and violation_codes != ''
),

codes as (
    select * from {{ ref('stg_violation_codes') }}
)

select
    f.serial_number,
    f.permit_number,
    f.inspection_date,
    f.violation_code,
    c.violation_description,
    c.violation_demerits
from flattened f
left join codes c
    on f.violation_code = cast(c.violation_code as varchar)
where f.violation_code != ''
