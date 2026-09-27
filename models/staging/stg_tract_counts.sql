select topic, cast(geoid as varchar) as geoid, category,
       cast(record_count as bigint) as record_count
from {{ source('raw', 'tract_counts') }}
