"""Overview / landing page for the Las Vegas Open-Data Explorer."""

import streamlit as st

from app_db import query

st.html(
    '<div class="elvis-eyebrow"><span>THE VALLEY, OBSERVED / ELVIS OPEN DATA</span>'
    '<span>36.1699° N &nbsp; 115.1398° W</span></div>'
    '<div class="elvis-cover"><h1>Beyond<br>the <em>Strip.</em></h1>'
    '<span class="elvis-star" aria-hidden="true">✳</span>'
    '<p>There’s a whole city behind the spectacle. Follow the data into '
    'the Las Vegas that lives, works, and grows.</p></div>'
    '<div class="elvis-section-label">01 / A SNAPSHOT OF THE VALLEY</div>'
)

# --- Headline numbers, straight from the dbt marts ---
art_n = int(query("select count(*) as n from main.mart_art_work_points")["n"][0])
insp_n = int(
    query("select sum(total_inspections) as n from main.mart_restaurants")["n"][0]
)
rest_n = int(query("select count(*) as n from main.mart_restaurants")["n"][0])
fire_n = int(query("select count(*) as n from main.mart_fire_prevention_inspections")["n"][0])
crime_n = int(query("select sum(incident_count) as n from main.mart_crime_monthly")["n"][0])
permit_n = int(query("select sum(permit_count) as n from main.mart_permits_monthly")["n"][0])
# CLV business licenses are temporarily offline (upstream feed outage); show the
# still-live City of Henderson count instead so the landing page stays whole.
lic_n = int(query("select sum(license_count) as n from main.mart_henderson_licenses_by_type")["n"][0])
marriage_n = int(query("select sum(license_count) as n from main.mart_marriage_monthly")["n"][0])
lake_ft = float(
    query(
        "select avg_elevation_ft as n from main.mart_lake_mead_monthly order by reading_month desc limit 1"
    )["n"][0]
)
hot_days = int(
    query(
        "select days_110f_plus as n from main.mart_weather_extreme_days order by observed_year desc limit 1 offset 1"
    )["n"][0]
)

c1, c2, c3 = st.columns(3)
c1.metric("Public artworks", f"{art_n:,}", help="City of Las Vegas")
c2.metric(
    "Restaurant inspections",
    f"{insp_n:,}",
    help=f"across {rest_n:,} Clark County restaurants",
)
c3.metric("Fire-inspected properties", f"{fire_n:,}", help="City of Las Vegas")

c4, c5, c6 = st.columns(3)
c4.metric("Metro calls for service", f"{crime_n:,}", help="LVMPD, two most recent years")
c5.metric("Building permits", f"{permit_n:,}", help="City of Las Vegas, 2004–2017")
c6.metric("Business licenses", f"{lic_n:,}", help="City of Henderson (Las Vegas feed temporarily offline)")

c7, c8, c9 = st.columns(3)
c7.metric("Marriage licenses", f"{marriage_n:,}", help="Clark County, 2007–2024")
c8.metric("Lake Mead elevation", f"{lake_ft:,.0f} ft", help="latest monthly average")
c9.metric("110°F+ days (prior recorded year)", f"{hot_days}", help="Las Vegas airport station")

st.html('<div class="elvis-section-label">02 / FOLLOW YOUR CURIOSITY</div>')

collections = [
    ("culture", "01 / CULTURE & PLACE", "The city as a canvas.",
     "Art, parks, and the places that give the valley its character.",
     [("views/public_art.py", "Discover public art"), ("views/parks.py", "Find a park"),
      ("views/marriage.py", "Explore marriage licenses"), ("views/tourism.py", "Tourism & gaming")]),
    ("civic", "02 / CIVIC LIFE", "Behind the everyday.",
     "How the valley builds, operates, and keeps its communities safe.",
     [("views/restaurants.py", "Restaurant inspections"), ("views/fire.py", "Fire inspections"),
      ("views/crime.py", "Metro calls for service"), ("views/building_permits.py", "Building permits"),
      ("views/business_licenses.py", "Business licenses"), ("views/short_term_rentals.py", "Short-term rentals"),
      ("views/road_construction.py", "Road construction")]),
    ("desert", "03 / THE DESERT", "At the desert’s edge.",
     "Water, heat, and air reveal a landscape living at the extremes.",
     [("views/lake_mead.py", "Follow Lake Mead’s water levels"), ("views/weather.py", "Explore desert heat"),
      ("views/air_quality.py", "Track air quality")]),
]
for column, (theme, label, title, description, links) in zip(st.columns(3), collections):
    with column:
        st.html(
            f'<div class="elvis-collection {theme}"><div class="elvis-section-label">{label}</div>'
            f'<h3>{title}</h3><p>{description}</p></div>'
        )
        for page, text in links:
            st.page_link(page, label=text)

st.divider()
left, right = st.columns([2, 1])
with left:
    st.subheader("A question is a good place to start.")
    st.write("Ask Tiresias to investigate the warehouse, or choose a collection to explore its maps and charts.")
    st.page_link("views/tiresias.py", label="Ask Tiresias →")
with right:
    st.markdown("**Open sources. Clear perspective.**")
    st.caption("Public records → Python → DuckDB → dbt → this atlas. Every view starts with a modeled dataset.")
    st.link_button("Explore the source ↗", "https://github.com/EvanWAppel/elvis")

st.html(
    '<div class="elvis-footer">AN INDEPENDENT ATLAS BY EVAN APPEL<br>'
    'SOURCES / CITY OF LAS VEGAS · CLARK COUNTY · LVMPD · SNHD · LVCVA · USBR · NOAA · EPA<br>'
    'Coverage and reporting periods vary by dataset. See individual collections for context.</div>'
)
