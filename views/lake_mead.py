"""Lake Mead water levels — the Colorado River drought, in one chart."""

import altair as alt
import pandas as pd
import streamlit as st

from app_db import query

st.title("🏜️ Lake Mead Water Levels")
st.caption(
    "Daily reservoir elevation at Hoover Dam (USBR), averaged by month. Full "
    "pool is 1,229 ft; the intake known as 'dead pool' sits near 895 ft."
)

# --- KPIs ---
kpi = query(
    """
    with m as (select * from main.mart_lake_mead_monthly)
    select
        (select avg_elevation_ft from m order by reading_month desc limit 1) as latest,
        max(avg_elevation_ft) as peak,
        (select reading_month from m order by reading_month desc limit 1) as latest_month
    from m
    """
)
latest = float(kpi["latest"][0])
peak = float(kpi["peak"][0])
c1, c2, c3 = st.columns(3)
c1.metric("Latest elevation", f"{latest:,.0f} ft", help=f"{kpi['latest_month'][0]:%b %Y}")
c2.metric("Record high (since 1935)", f"{peak:,.0f} ft")
c3.metric("Below full pool", f"{1229 - latest:,.0f} ft", delta=f"{latest - peak:,.0f} ft vs peak", delta_color="inverse")

st.divider()

# --- Elevation over time ---
monthly = query(
    "select reading_month, avg_elevation_ft from main.mart_lake_mead_monthly order by 1"
)
st.subheader("Elevation over time")
base = alt.Chart(monthly).encode(
    x=alt.X("reading_month:T", title=None),
    y=alt.Y(
        "avg_elevation_ft:Q",
        title="Elevation (ft)",
        scale=alt.Scale(zero=False),
    ),
)
line = base.mark_line(color="#1c7ed6")
# Reference lines for full pool and dead pool.
rules = (
    alt.Chart(pd.DataFrame({"level": [1229, 895]}))
    .mark_rule(strokeDash=[6, 4], color="#868e96")
    .encode(y="level:Q")
)
st.altair_chart(
    (line + rules).interactive(),
    width="stretch",
)

st.caption(
    "The steady decline since ~2000 reflects a prolonged Colorado River drought "
    "and structural over-allocation of the river."
)
