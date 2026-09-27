select
    cast(geoid as varchar) as geoid,
    tract_name,
    try_cast(population as bigint) as population,
    cast(boundary_vintage as varchar) as boundary_vintage,
    cast(population_vintage as varchar) as population_vintage,
    population_source,
    cities_json,
    geometry_json
from {{ source('raw', 'census_tracts') }}
