{{ config(materialized='table') }}

-- Long-form monthly LVCVA indicators (visitor volume, occupancy, ADR, airport
-- passengers, gaming revenue by area, ...). The page selects metrics by name.

with indicators as (
    select * from {{ ref('stg_lvcva_indicators') }}
)

select
    metric,
    indicator_month,
    value
from indicators
order by metric, indicator_month
