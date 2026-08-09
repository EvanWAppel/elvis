{{ config(materialized='table') }}

-- A capped random sample of geolocated calls for the map. The full table is
-- ~900k points — far too many to render client-side — so we down-sample to a
-- representative set that still shows the spatial hot spots.

with calls as (
    select
        incident_number,
        incident_type,
        classification,
        incident_date,
        address,
        latitude,
        longitude
    from {{ ref('stg_crime_calls') }}
    where latitude between 35.8 and 36.4
      and longitude between -115.5 and -114.9
)

select * from calls using sample 12000 rows
