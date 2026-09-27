select topic, geoid
from {{ ref('mart_tract_metrics') }}
where record_count < 0
   or (rate_per_1000 is not null and
       (coverage <> 'available' or not rate_allowed or population is null or population <= 0
        or abs(rate_per_1000 - record_count * 1000.0 / population) > 0.000001))
   or (coverage <> 'available' and record_count = 0)
