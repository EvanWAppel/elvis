select topic, cast(geoid as varchar) as geoid, coverage, period,
       cast(rate_allowed as boolean) as rate_allowed
from {{ source('raw', 'tract_coverage') }}
