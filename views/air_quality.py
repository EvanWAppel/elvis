"""Air quality — EPA AQS daily PM2.5 and ozone for Clark County."""

import altair as alt
import streamlit as st

from app_db import query

st.title("💨 Air Quality")
st.caption(
    "EPA Air Quality System daily AQI across the Las Vegas metro (Clark County) — "
    "PM2.5 (fine particulates) and ozone. Lower AQI is cleaner air; 50+ is "
    "'Moderate', 100+ is unhealthy for sensitive groups."
)

daily = query("select observed_date, parameter, max_aqi from main.mart_air_quality_daily")
if daily.empty:
    st.info("No air-quality data is loaded in this build.")
    st.stop()

# --- KPIs ---
kpi = query(
    """
    select
        count(distinct observed_date)                                as days,
        sum(case when max_aqi <= 50 then 1 else 0 end)::double
            / count(*) * 100                                         as good_pct,
        max(max_aqi)                                                 as worst
    from main.mart_air_quality_daily
    """
)
c1, c2, c3 = st.columns(3)
c1.metric("Days measured", f"{int(kpi['days'][0]):,}")
c2.metric("'Good' air days (AQI ≤ 50)", f"{kpi['good_pct'][0]:.0f}%")
c3.metric("Worst AQI on record", f"{int(kpi['worst'][0])}")

st.divider()

# --- Monthly average AQI by pollutant ---
monthly = query(
    "select observed_month, parameter, avg_aqi from main.mart_air_quality_monthly order by 1"
)
st.subheader("Average AQI per month")
trend = (
    alt.Chart(monthly)
    .mark_line()
    .encode(
        x=alt.X("observed_month:T", title=None),
        y=alt.Y("avg_aqi:Q", title="Avg AQI"),
        color=alt.Color("parameter:N", title="Pollutant"),
        tooltip=[
            "parameter",
            alt.Tooltip("observed_month:T", title="Month"),
            alt.Tooltip("avg_aqi:Q", title="Avg AQI"),
        ],
    )
)
st.altair_chart(trend, width="stretch")

# --- AQI category distribution by year ---
st.subheader("Air-quality days by category")
cats = query(
    """
    select
        year(observed_date) as observed_year,
        case
            when max_aqi <= 50 then 'Good'
            when max_aqi <= 100 then 'Moderate'
            when max_aqi <= 150 then 'Unhealthy (sensitive)'
            else 'Unhealthy+'
        end                 as category,
        count(*)            as days
    from main.mart_air_quality_daily
    group by 1, 2
    """
)
order = ["Good", "Moderate", "Unhealthy (sensitive)", "Unhealthy+"]
cat_chart = (
    alt.Chart(cats)
    .mark_bar()
    .encode(
        x=alt.X("observed_year:O", title=None),
        y=alt.Y("days:Q", title="Days"),
        color=alt.Color(
            "category:N",
            title="AQI category",
            scale=alt.Scale(
                domain=order, range=["#2f9e44", "#f59f00", "#e8590c", "#c92a2a"]
            ),
            sort=order,
        ),
        tooltip=["observed_year", "category", "days"],
    )
)
st.altair_chart(cat_chart, width="stretch")
