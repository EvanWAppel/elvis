-- City of Las Vegas business licenses (non-spatial registry; no coordinates).

with source as (
    select * from {{ source('raw', 'business_licenses') }}
)

select
    "License__"             as license_no,
    "Business_Name"         as business_name,
    "Type_of_Business"      as type_of_business,
    "Status"                as status,
    "Zip_Code"              as zip_code,
    "Within_City_Limits"    as within_city_limits,
    "Owner_and_Owner_Title" as owner
from source
