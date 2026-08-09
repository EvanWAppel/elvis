-- Clark County marriage licenses, one row per license. Dates are MM/DD/YYYY
-- strings; gender/marital values drift across years so we keep them as-is.

with source as (
    select * from {{ source('raw', 'marriage_licenses') }}
)

select
    try_strptime("LicenseIssueDate", '%m/%d/%Y')::date as license_date,
    nullif(upper(trim("MailingState")), '')            as mailing_state,
    nullif(upper(trim("MailingCountry")), '')          as mailing_country,
    nullif(upper(trim("Party1Gender")), '')            as party1_gender,
    nullif(upper(trim("Party2Gender")), '')            as party2_gender
from source
where "LicenseIssueDate" is not null
