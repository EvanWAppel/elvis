# Valley coverage

Source audit: 2026-09-26. This describes source scope, not a guarantee that every
record is complete or that the current public deployment contains these changes.
Data is a build-time snapshot. “Gap” means no suitable integrated source has been
verified; it does not mean the city has no activity or that no source exists.

| Topic | Las Vegas | Henderson | North Las Vegas | Regional / county context |
| --- | --- | --- | --- | --- |
| Public art | City collection | City collection added | Gap: no verified art feed | Collection jurisdiction differs from artwork location |
| Restaurant inspections | SNHD regional source | SNHD regional source | SNHD regional source | Coverage depends on establishment geocoding; no new municipal feed needed |
| Fire inspections | City inspection feed | Gap: station layers are not inspections | Gap: station layers are not inspections | Do not substitute facilities for inspection records |
| Calls for service | LVMPD source | Different measure — see Crime reports row | Gap: no verified comparable call feed | LVMPD also covers unincorporated areas; not universal valley police coverage |
| Crime reports | Use calls-for-service instead | City crime-report feed added (recent years) | Gap: no verified bulk feed | A **report** is not a **call for service**; the two are never combined or compared. Henderson annual volumes differ across years — count-only, no rate |
| Building permits | Archived permits | Residential permits only | Gap: online permit portal located; bulk feed not verified | Henderson grading/other layers are discovery candidates, not yet harmonized |
| Business licenses | Existing feed disabled after outage | Existing city registry | Gap: searchable portal located; bulk feed not verified | A licensing-jurisdiction lookup is not a license dataset |
| Short-term rentals | Existing registrations | Existing registrations | Existing approvals via county GIS | Definitions/statuses differ; tract counts are inventory records |
| Parks | Existing inventory | Existing inventory | Existing county-hosted inventory | Existing county inventory retained; counts use representative points |
| Road construction | CIP projects + optional NDOT | Transportation CIP lines added + optional NDOT | NDOT state routes only; local-road source gap | Local ROW permits remain incomplete; different source phases retained |
| Marriage licenses | Regional | Regional | Regional | County license issuance; no invented city/tract breakdown |
| Tourism & gaming | Regional/reporting-area series | Regional/reporting-area series | Regional/reporting-area series | LVCVA reporting areas do not imply municipal parity |
| Lake Mead | Shared regional context | Shared regional context | Shared regional context | Reservoir time series, not tract observations |
| Weather extremes | Shared station context | Shared station context | Shared station context | Airport station is not a city-by-city temperature map |
| Air quality | Monitoring-site context | Monitoring-site context | Monitoring-site context | EPA site measurements are not full-city or tract estimates |
| Census geography/population | Added | Added | Added | Full 2020 tracts intersecting the valley extent; matching 2020 population |

## Maps in this increment

**Compare Census Tracts** supports full-snapshot counts for calls, parks, rental
registrations, and public art. Calls and rentals offer rates per 1,000 residents
only for fully covered tract footprints with positive known population. Rates
use **2020 Census population**, not current population, and are not annualized.
Parks and public art retain count-only comparisons. Point and road maps remain.

City selection retains the **entire tract** if it intersects a selected city by
positive area. It does not clip counts or population. A tract crossing a city
boundary can appear in more than one city selection, but appears only once when
both are selected. Tract values must not be summed as city totals. All cities use
the same color domain for a topic/metric, fixed before city selection.

Gray means missing coverage or an unavailable rate. Covered tracts with no
assigned source records show zero; partial/unavailable footprints do not acquire
an invented zero. Observed records outside a source's intended footprint remain
visible with their coverage limitation, without rates. Assignment diagnostics
account for every record, including missing coordinates and records outside the
mapped tracts. Boundary/overlap ties are assigned once, to the lowest GEOID.

## Verified metadata and source contracts

- [Census tract layer](https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb/tigerWMS_Census2020/MapServer/6):
  U.S. Census Bureau; keyless GeoJSON queries, Clark County (`STATE=32`,
  `COUNTY=003`). `GEOID`, `NAME`, and `POP100`; 2020 geometry and population,
  polygon precision. Frozen decennial vintage, not a current demographic feed.
- [Census incorporated places](https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb/tigerWMS_Census2020/MapServer/26):
  matching 2020 municipal footprints. Later annexations are not represented.
- [Henderson public art](https://maps.cityofhenderson.com/arcgis/rest/services/public/OpenDataRecreation/MapServer/10):
  city publisher; keyless query; point inventory keyed by `OBJECTID`, with title,
  artist, location, and detail URL. No verified historical time series or update
  cadence. No explicit reuse license in the layer metadata; retain attribution.
- [Henderson transportation CIP](https://maps.cityofhenderson.com/arcgis/rest/services/public/CIP/MapServer):
  city publisher; keyless transportation line layers 7 and 8, not all capital
  projects. Project number, phase/status, schedule, and geometry. Exact duplicate
  project/path pairs across display layers are collapsed; disjoint segments stay
  separate. This is not a complete ROW/closure feed. Update cadence/history and
  explicit reuse license are not supplied by the layer metadata.
- [Henderson residential permits](https://maps.cityofhenderson.com/arcgis/rest/services/public/OpenDevPermits/MapServer/1):
  existing integration; residential scope confirmed. No valuation field in the
  selected schema. Additional permit layers require grain/deduplication review.
- [Henderson public safety](https://maps.cityofhenderson.com/arcgis/rest/services/public/OpenDataPublicSafety/MapServer):
  city publisher; keyless query; per-year "Crime Data {year}" point layers
  (2014–2025) plus a rolling "Daily Crime Data" layer. Recent years (`[2024, 2025]`)
  are ingested as the **`henderson_crime`** tract topic, keyed by
  `henderson:{year}:{OBJECTID}`, with offense (`INC_PRIMAR`), beat, address, and
  occurrence date (`OCCURRED_S`, epoch-ms). These are crime **reports** — a
  different measure from LVMPD calls-for-service; they are **never merged with the
  calls map** and carry no per-resident rate. Verified 2026-09-27: 2025 ≈ 27,168
  and 2024 ≈ 6,405 features — the cross-year gap is pending human review of annual
  completeness before the topic is presented as complete. No explicit reuse license
  in the layer metadata; retain attribution.
- [North Las Vegas GIS catalog](https://services5.arcgis.com/Y7XI8T2pEBpNKRDw/arcgis/rest/services):
  catalog discovery found a general facilities service and utility/planning
  layers, not a verified equivalent for calls, art, inspections, or local roads.
  Existing NLV parks/rentals remain sourced through county GIS to avoid duplicates.
- [North Las Vegas permit portal](https://www.cityofnorthlasvegas.com/business/development-services):
  public application/search access is not yet a verified reproducible bulk feed.
  [Business license information](https://www.cityofnorthlasvegas.com/business/business-licenses/business-license-faqs)
  also points to interactive search; bulk access remains unverified.

Live validation processes source data without displaying records. Human review
of source meaning, coverage, and plausible totals remains separate from automated
schema, geometry, and reconciliation checks, per project instructions.
