"""Las Vegas Open-Data Explorer — the interactive demo behind the portfolio.

Raw Las Vegas / Clark County open data is loaded into DuckDB, modeled with dbt,
and served here. This entry point just wires up the multi-page navigation; each
page lives in ``views/`` and queries the dbt marts via ``app_db.query``.
"""

import streamlit as st

from ui import apply_theme

st.set_page_config(
    page_title="Elvis — Las Vegas, in data",
    page_icon="✳",
    layout="wide",
)

apply_theme()

pages = {
    "The atlas": [
        st.Page("views/overview.py", title="Overview", default=True),
        st.Page("views/tiresias.py", title="Ask Tiresias"),
    ],
    "01 / Culture & place": [
        st.Page("views/public_art.py", title="Public Art"),
        st.Page("views/parks.py", title="Parks"),
        st.Page("views/marriage.py", title="Marriage Licenses"),
        st.Page("views/tourism.py", title="Tourism & Gaming"),
    ],
    "02 / Civic life": [
        st.Page("views/restaurants.py", title="Restaurant Inspections"),
        st.Page("views/fire.py", title="Fire Inspections"),
        st.Page("views/crime.py", title="Metro Calls"),
        st.Page("views/building_permits.py", title="Building Permits"),
        st.Page("views/business_licenses.py", title="Business Licenses"),
        st.Page("views/short_term_rentals.py", title="Short-Term Rentals"),
        st.Page("views/road_construction.py", title="Road Construction"),
    ],
    "03 / The desert": [
        st.Page("views/lake_mead.py", title="Lake Mead"),
        st.Page("views/weather.py", title="Desert Heat"),
        st.Page("views/air_quality.py", title="Air Quality"),
    ],
}

st.navigation(pages).run()
