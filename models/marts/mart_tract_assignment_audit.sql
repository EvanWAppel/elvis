select topic, source_records, assigned_records, invalid_coordinates,
       outside_tracts, boundary_ties
from {{ source('raw', 'tract_assignment_audit') }}
