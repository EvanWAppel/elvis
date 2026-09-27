select a.topic
from {{ ref('mart_tract_assignment_audit') }} a
left join (
    select topic, sum(record_count) as records
    from {{ ref('stg_tract_counts') }} group by 1
) c using (topic)
where a.source_records <> a.assigned_records + a.invalid_coordinates + a.outside_tracts
   or a.assigned_records <> coalesce(c.records, 0)
