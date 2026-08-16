"""City of Las Vegas business licenses — what kinds of businesses, and where."""

import altair as alt
import streamlit as st

from app_db import query

st.title("📋 Business Licenses")
st.caption("Business-license registries for the Las Vegas Valley.")

# --- City of Las Vegas: temporarily offline ---
# The CLV Business_Licenses_OpenData feed is down upstream, so raw.business_licenses
# and its marts are disabled (see build_warehouse.py + the stg/mart models). Re-enable
# them to restore the searchable CLV roster and type breakdown below the Henderson section.
st.header("🎰 City of Las Vegas business licenses")
st.info(
    "The City of Las Vegas business-license feed is temporarily unavailable "
    "upstream, so this section is offline. The City of Henderson data below is "
    "unaffected."
)

st.divider()

# --- Henderson business licenses ---
st.header("🏙️ Henderson business licenses")
hen_kpi = query(
    """
    select sum(license_count) as total, sum(active_count) as active,
           count(*) as types
    from main.mart_henderson_licenses_by_type
    """
)
h1, h2, h3 = st.columns(3)
h1.metric("Licenses on file", f"{int(hen_kpi['total'][0]):,}")
h2.metric("Active", f"{int(hen_kpi['active'][0]):,}")
h3.metric("License types", f"{int(hen_kpi['types'][0]):,}")

hen_types = query(
    """
    select license_type, license_count
    from main.mart_henderson_licenses_by_type
    order by license_count desc
    limit 20
    """
)
hen_chart = (
    alt.Chart(hen_types)
    .mark_bar(color="#e8590c")
    .encode(
        x=alt.X("license_count:Q", title="Licenses"),
        y=alt.Y("license_type:N", sort="-x", title=None),
        tooltip=["license_type", alt.Tooltip("license_count:Q", title="Licenses", format=",")],
    )
)
st.altair_chart(hen_chart, width="stretch")
