"""Las Vegas weather — how hot, and how much hotter it's getting."""

import altair as alt
import streamlit as st

from app_db import query

st.title("🌡️ Desert Heat")
st.caption(
    "Daily temperatures at Harry Reid International Airport (NOAA GHCN-Daily, "
    "1948–present). The valley's signature is extreme summer heat."
)

# --- KPIs ---
kpi = query(
    """
    select
        max(record_high_f)                                  as record_high,
        (select days_110f_plus from main.mart_weather_extreme_days
          order by observed_year desc limit 1 offset 1)     as recent_110,
        (select observed_year from main.mart_weather_extreme_days
          order by observed_year desc limit 1 offset 1)     as recent_year
    from main.mart_weather_monthly
    """
)
c1, c2, c3 = st.columns(3)
c1.metric("All-time record high", f"{kpi['record_high'][0]:.0f}°F")
c2.metric(
    f"110°F+ days in {int(kpi['recent_year'][0])}",
    f"{int(kpi['recent_110'][0])}",
)
c3.metric("Station record since", "1948")

st.divider()

# --- Extreme heat days per year ---
extreme = query(
    """
    select observed_year, days_100f_plus, days_110f_plus, avg_high_f
    from main.mart_weather_extreme_days
    order by observed_year
    """
)
st.subheader("Extreme-heat days per year")
st.caption("Days reaching 100°F and 110°F. The most recent year is partial.")
melted = extreme.melt(
    id_vars="observed_year",
    value_vars=["days_100f_plus", "days_110f_plus"],
    var_name="threshold",
    value_name="days",
)
melted["threshold"] = melted["threshold"].map(
    {"days_100f_plus": "100°F+", "days_110f_plus": "110°F+"}
)
heat_chart = (
    alt.Chart(melted)
    .mark_bar()
    .encode(
        x=alt.X("observed_year:O", title=None),
        y=alt.Y("days:Q", title="Days"),
        color=alt.Color(
            "threshold:N",
            title=None,
            scale=alt.Scale(domain=["100°F+", "110°F+"], range=["#f08c00", "#e03131"]),
        ),
        tooltip=["observed_year", "threshold", "days"],
    )
)
st.altair_chart(heat_chart, width="stretch")

# --- Average annual high ---
st.subheader("Average daily high, by year")
avg_chart = (
    alt.Chart(extreme)
    .mark_line(point=True, color="#e8590c")
    .encode(
        x=alt.X("observed_year:O", title=None),
        y=alt.Y("avg_high_f:Q", title="Avg high (°F)", scale=alt.Scale(zero=False)),
        tooltip=[
            "observed_year",
            alt.Tooltip("avg_high_f:Q", title="Avg high °F"),
        ],
    )
)
st.altair_chart(avg_chart, width="stretch")
