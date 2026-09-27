"""LVMPD calls-for-service — recent-year patterns across type, time, and place."""

import altair as alt
import streamlit as st

from app_db import query
from tract_map import render_tract_map
from ui import PINK, SEQUENTIAL, atlas_chart

st.title("Metro Calls for Service")
st.caption(
    "Las Vegas Metropolitan Police Department calls for service (two most recent "
    "years). Charts summarize the full source snapshot; the map uses full-data census-tract counts."
)

# --- KPIs ---
kpi = query(
    """
    select
        sum(incident_count)                          as total_calls,
        (select count(*) from main.mart_crime_by_type) as distinct_types
    from main.mart_crime_monthly
    """
)
span = query(
    """
    select
        min(incident_month) as first_month,
        max(incident_month) as last_month
    from main.mart_crime_monthly
    """
)
c1, c2, c3 = st.columns(3)
c1.metric("Calls for service", f"{int(kpi['total_calls'][0]):,}")
c2.metric("Distinct incident types", f"{int(kpi['distinct_types'][0]):,}")
c3.metric(
    "Period",
    f"{span['first_month'][0]:%b %Y} – {span['last_month'][0]:%b %Y}",
)

st.divider()

# --- Monthly trend ---
monthly = query(
    "select incident_month, incident_count from main.mart_crime_monthly order by 1"
)
st.subheader("Calls per month")
trend = (
    alt.Chart(monthly)
    .mark_line(point=True, color=PINK)
    .encode(
        x=alt.X("incident_month:T", title=None),
        y=alt.Y("incident_count:Q", title="Calls"),
        tooltip=[
            alt.Tooltip("incident_month:T", title="Month"),
            alt.Tooltip("incident_count:Q", title="Calls", format=","),
        ],
    )
)
atlas_chart(trend, width="stretch")

# --- Top incident types ---
types = query(
    """
    select incident_type, sum(incident_count) as incident_count
    from main.mart_crime_by_type
    group by 1
    order by incident_count desc
    limit 15
    """
)
st.subheader("Most common call types")
types_chart = (
    alt.Chart(types)
    .mark_bar(color=PINK)
    .encode(
        x=alt.X("incident_count:Q", title="Calls"),
        y=alt.Y("incident_type:N", sort="-x", title=None),
        tooltip=[
            "incident_type",
            alt.Tooltip("incident_count:Q", title="Calls", format=","),
        ],
    )
)
atlas_chart(types_chart, width="stretch")

# --- Hour x weekday heatmap ---
heat = query(
    "select weekday, hour_of_day, incident_count from main.mart_crime_by_hour_weekday"
)
weekday_order = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
]
st.subheader("When calls happen")
st.caption("Calls for service by hour of day and day of week.")
heatmap = (
    alt.Chart(heat)
    .mark_rect()
    .encode(
        x=alt.X("hour_of_day:O", title="Hour of day"),
        y=alt.Y("weekday:N", sort=weekday_order, title=None),
        color=alt.Color(
            "incident_count:Q", title="Calls", scale=alt.Scale(range=SEQUENTIAL)
        ),
        tooltip=[
            "weekday",
            "hour_of_day",
            alt.Tooltip("incident_count:Q", title="Calls", format=","),
        ],
    )
)
atlas_chart(heatmap, width="stretch")

# --- Map (complete snapshot, computed at build time) ---
st.subheader("Where calls happen")
st.caption(
    "Map controls apply to the tract comparison below; charts above summarize the full source snapshot."
)
render_tract_map("calls", key="crime_tracts")
