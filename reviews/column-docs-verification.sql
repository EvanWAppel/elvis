-- Column-doc verification queries for PR #29 (Tiresias all-domains).
--
-- Each block checks a factual claim the new column docs make. Evan runs these and
-- compares the output to the claim. Claude never sees the data. Run with:
--
--     uv run python reviews/run_verification.py
--
-- (read-only connection · prints each CHECK line, then its result)

-- CHECK: road — is_full_closure is set only on NDOT 511 rows (null for both CIP sources)
select data_source, count(*) as rows, count(is_full_closure) as closure_flag_set
from mart_road_construction group by 1 order by 1;

-- CHECK: road — grain is per segment (Henderson rows > projects) · road_name null for Henderson · contractor/url coverage per source
select data_source, count(*) as rows, count(distinct project_name) as projects,
       count(road_name) as has_road_name, count(contractor) as has_contractor, count(url) as has_url
from mart_road_construction group by 1 order by 1;

-- CHECK: road — Henderson category is always 'Transportation' · CLV category is CATEGORY/ProjType · status values look like phases
select data_source, category, status, count(*) as n
from mart_road_construction group by all order by data_source, n desc limit 40;

-- CHECK: crime — coverage is 2025-2026 only, latest month partial
select min(incident_month) as first_month, max(incident_month) as last_month,
       arg_min(incident_count, incident_month) as first_month_calls,
       arg_max(incident_count, incident_month) as last_month_calls
from mart_crime_monthly;

-- CHECK: crime — weekday is a full English name · hour_of_day is 0-23
select list(distinct weekday order by weekday) as weekdays,
       min(hour_of_day) as min_hour, max(hour_of_day) as max_hour
from mart_crime_by_hour_weekday;

-- CHECK: crime — classification is a broad category, incident_type is specific
select classification, count(*) as incident_types, sum(incident_count) as calls
from mart_crime_by_type group by 1 order by calls desc limit 15;

-- CHECK: short-term rentals — NLV status always 'Approved' · status per jurisdiction
select jurisdiction, status, count(*) as n
from mart_short_term_rentals group by all order by jurisdiction, n desc;

-- CHECK: short-term rentals — Henderson category = 'Max occupancy N', NLV category null, LV = business type
select jurisdiction, category, count(*) as n
from mart_short_term_rentals group by all order by jurisdiction, n desc limit 30;

-- CHECK: short-term rentals — NLV business_name looks like owner names · date ranges per jurisdiction
select jurisdiction, min(issued_date) as first_date, max(issued_date) as last_date,
       any_value(business_name) as sample_name
from mart_short_term_rentals group by 1 order by 1;

-- CHECK: parks — has_water: LV true/false, Henderson true/false, Clark County + NLV null
select jurisdiction, has_water, count(*) as parks, count(acres) as has_acres
from mart_parks group by all order by jurisdiction, has_water;

-- CHECK: air quality — parameter is exactly 'PM2.5' / 'Ozone' · from 2015 · concentration scales differ (ug/m3 vs ppm)
select parameter, min(observed_date) as first_day, max(observed_date) as last_day,
       min(avg_concentration) as min_conc, max(avg_concentration) as max_conc
from mart_air_quality_daily group by 1;

-- CHECK: marriage — coverage 2007-2025
select min(license_month) as first_month, max(license_month) as last_month from mart_marriage_monthly;

-- CHECK: marriage — origin is uppercase US state else country · 'UNITED STATES' appears for state-less US rows
select origin, license_count from mart_marriage_by_origin order by license_count desc limit 20;

-- CHECK: marriage — same-sex licenses begin in late 2014
select license_year, couple_type, license_count from mart_marriage_by_gender_year
where license_year between 2012 and 2016 order by 1, 2;

-- CHECK: tracts — record_count: zero-filled only for 'available' · may be non-null for 'partial'/'unavailable' · rate only when available
select topic, coverage, count(*) as tracts, count(record_count) as has_count,
       count(*) filter (where record_count = 0) as zeros, count(rate_per_1000) as has_rate
from mart_tract_metrics group by all order by topic, coverage;

-- CHECK: tracts — period format and rate_allowed per topic
select topic, any_value(period) as period, bool_or(rate_allowed) as rate_allowed
from mart_tract_metrics group by 1 order by 1;

-- CHECK: LVCVA — metric names ('Visitor Volume', '%En/Deplaned Passengers%', 'Gaming Revenue <area>', colon optional)
select metric, count(*) as months, min(indicator_month) as first_month, max(indicator_month) as last_month
from mart_lvcva_indicators group by 1 order by 1;

-- CHECK: LVCVA — the Clark County gaming row is the total of the areas (so summing all would double-count)
select indicator_month,
       sum(value) filter (where metric ilike 'Gaming Revenue%' and metric not ilike '%Clark County%') as sum_of_areas,
       max(value) filter (where metric ilike 'Gaming Revenue%' and metric ilike '%Clark County%') as clark_county_row
from mart_lvcva_indicators group by 1 order by 1 desc limit 6;

-- CHECK: restaurants — inspection_type values (doc says 'as published') · grade codes A/B/C/F/N/P/S/O
select inspection_type, count(*) as n from mart_inspection_history group by 1 order by n desc limit 15;

-- CHECK: restaurants — grade code set
select inspection_grade, count(*) as n from mart_inspection_history group by 1 order by n desc;

-- CHECK: weather, Lake Mead, permits — date coverage (no period is documented · confirm none is needed)
select 'weather' as source, min(observed_month)::date as first, max(observed_month)::date as last from mart_weather_monthly
union all select 'lake_mead', min(reading_month)::date, max(reading_month)::date from mart_lake_mead_monthly
union all select 'clv_permits', min(issue_month)::date, max(issue_month)::date from mart_permits_monthly
union all select 'henderson_permits', min(issue_month)::date, max(issue_month)::date from mart_henderson_permits;

-- CHECK: fire — Zip stored as a number · fiscal-year range · violations totals plausible
select min(first_fiscal_year) as first_fy, max(last_fiscal_year) as last_fy,
       typeof(any_value(Zip)) as zip_type, max(total_violations) as max_total_violations
from mart_fire_prevention_inspections;
