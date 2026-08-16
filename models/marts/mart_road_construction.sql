{{ config(materialized='table') }}

-- Metro road construction, one row per project/event: City of Las Vegas Capital
-- Improvement Program lines plus (when a Nevada 511 key is configured) NDOT
-- state-route roadwork and closures. Geometry travels as a JSON path string.
with projects as (
    select * from {{ ref('stg_road_construction') }}
)

select
    data_source,
    project_name,
    description,
    status,
    category,
    road_name,
    extent,
    start_date,
    end_date,
    contractor,
    is_full_closure,
    url,
    path_json,
    latitude,
    longitude
from projects
order by data_source, end_date desc nulls last, project_name
