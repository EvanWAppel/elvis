"""Overview / landing page for the Las Vegas Open-Data Explorer."""

import streamlit as st

from app_db import query

st.title("🎰 Las Vegas Open-Data Explorer")
st.markdown(
    "Raw open data from the Las Vegas Valley — loaded into **DuckDB**, modeled "
    "with **dbt**, and served live through this app. Pick a dataset from the "
    "sidebar to explore."
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
c9.metric("110°F+ days last year", f"{hot_days}", help="Las Vegas airport station")

st.divider()

col_a, col_b = st.columns(2)
with col_a:
    st.subheader("What's inside")
    st.markdown(
        "- **🗺️ Public Art** — an interactive map of the City's public art "
        "collection, filterable by council ward.\n"
        "- **🍽️ Restaurant Inspections** — Southern Nevada Health District "
        "inspections across **all of Clark County**: a searchable, sortable "
        "restaurant list with names and addresses, grades, top violations, and "
        "compliance trends since 2020.\n"
        "- **🔥 Fire Inspections** — City of Las Vegas fire-prevention "
        "inspections of multi-unit residential properties.\n"
        "- **🚨 Metro Calls** — LVMPD calls for service: what, when, and where, "
        "with a time-of-day heatmap and a hex-binned map.\n"
        "- **🏗️ Building Permits** — construction volume and valuation over the "
        "valley's boom years.\n"
        "- **📋 Business Licenses** — a searchable registry of what businesses "
        "operate in the city.\n"
        "- **🏠 Short-Term Rentals** & **🌳 Parks** — mapped metro-wide (Las Vegas, "
        "Henderson, Clark County, North Las Vegas); parks flagged for water features.\n"
        "- **💍 Marriage Licenses** — the wedding capital's spikes, seasonality, "
        "and where couples come from.\n"
        "- **🎢 Tourism & Gaming** — LVCVA visitor volume, hotel rates, airport "
        "passengers, and monthly gaming revenue by area.\n"
        "- **🏜️ Lake Mead** & **🌡️ Desert Heat** — the Colorado River drought and "
        "the valley's rising extreme-heat days."
    )

with col_b:
    st.subheader("How it's built")
    st.markdown(
        "Every number on every page is a **dbt** model materialized in "
        "**DuckDB** and queried live — the same extract → load → model → test → "
        "serve workflow a data team runs in production.\n\n"
        "**Source** (City / SNHD open data) → **Load** (Python) → "
        "**Model + Test** (dbt) → **Serve** (Streamlit)."
    )
    st.link_button("Source on GitHub ↗", "https://github.com/EvanWAppel/elvis")

st.caption(
    "Data: City of Las Vegas, Clark County & LVMPD open data, SNHD, LVCVA, "
    "USBR (Lake Mead), and NOAA."
)
