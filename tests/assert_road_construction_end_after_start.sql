-- Singular data test: a road-construction project's end_date must not fall
-- before its start_date. Rows where either date is null are out of scope (the
-- feeds legitimately omit one or both). Dates are upstream-feed passthrough, so
-- this is a `warn` signal — a bad upstream date shouldn't abort the deploy build.
{{ config(severity='warn') }}
select
    data_source,
    project_name,
    start_date,
    end_date
from {{ ref('mart_road_construction') }}
where start_date is not null
  and end_date is not null
  and end_date < start_date
