"""Las Vegas Open-Data Explorer — the interactive demo behind the portfolio.

Raw Las Vegas / Clark County open data is loaded into DuckDB, modeled with dbt,
and served here. This entry point just wires up the multi-page navigation; each
page lives in ``views/`` and queries the dbt marts via ``app_db.query``.
"""

import streamlit as st

st.set_page_config(
    page_title="Las Vegas Open-Data Explorer",
    page_icon="🎰",
    layout="wide",
)

pages = [
    st.Page("views/overview.py", title="Overview", icon="🏠", default=True),
    st.Page("views/public_art.py", title="Public Art", icon="🗺️"),
    st.Page("views/restaurants.py", title="Restaurant Inspections", icon="🍽️"),
    st.Page("views/fire.py", title="Fire Inspections", icon="🔥"),
    st.Page("views/crime.py", title="Metro Calls", icon="🚨"),
    st.Page("views/building_permits.py", title="Building Permits", icon="🏗️"),
    st.Page("views/business_licenses.py", title="Business Licenses", icon="📋"),
    st.Page("views/short_term_rentals.py", title="Short-Term Rentals", icon="🏠"),
    st.Page("views/parks.py", title="Parks", icon="🌳"),
    st.Page("views/marriage.py", title="Marriage Licenses", icon="💍"),
    st.Page("views/tourism.py", title="Tourism & Gaming", icon="🎢"),
    st.Page("views/lake_mead.py", title="Lake Mead", icon="🏜️"),
    st.Page("views/weather.py", title="Desert Heat", icon="🌡️"),
]

st.navigation(pages).run()
