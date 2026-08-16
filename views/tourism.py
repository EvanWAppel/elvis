"""LVCVA tourism indicators — visitors, gaming revenue, and air travel."""

import altair as alt
import streamlit as st

from app_db import query

st.title("🎢 Tourism, Gaming & Air Travel")
st.caption(
    "Monthly Southern Nevada indicators from the LVCVA Research Center: visitor "
    "volume, hotel occupancy and rates, airport passengers, and gaming revenue "
    "by area (2019–present)."
)


def line_of(metric_like: str, title: str, color: str, fmt: str = ",.0f"):
    df = query(
        f"""
        select indicator_month, value
        from main.mart_lvcva_indicators
        where metric ilike '{metric_like}'
        order by indicator_month
        """
    )
    if df.empty:
        return None
    return (
        alt.Chart(df)
        .mark_line(color=color)
        .encode(
            x=alt.X("indicator_month:T", title=None),
            y=alt.Y("value:Q", title=title, axis=alt.Axis(format="~s")),
            tooltip=[
                alt.Tooltip("indicator_month:T", title="Month"),
                alt.Tooltip("value:Q", title=title, format=fmt),
            ],
        )
    )


# --- Visitor volume ---
st.subheader("Visitor volume")
st.caption("The 2020 pandemic collapse and recovery are unmistakable.")
vv = line_of("Visitor Volume", "Visitors", "#1098ad")
if vv is not None:
    st.altair_chart(vv, width="stretch")

# --- Gaming revenue by area ---
st.subheader("Gaming revenue by area")
gaming = query(
    """
    select
        regexp_replace(metric, '^Gaming Revenue\\s*:?\\s*', '') as area,
        indicator_month,
        value
    from main.mart_lvcva_indicators
    where metric ilike 'Gaming Revenue%'
      and metric not ilike '%Clark County%'
    order by indicator_month
    """
)
if not gaming.empty:
    gaming_chart = (
        alt.Chart(gaming)
        .mark_line()
        .encode(
            x=alt.X("indicator_month:T", title=None),
            y=alt.Y("value:Q", title="Revenue ($)", axis=alt.Axis(format="~s")),
            color=alt.Color("area:N", title="Area"),
            tooltip=[
                "area",
                alt.Tooltip("indicator_month:T", title="Month"),
                alt.Tooltip("value:Q", title="Revenue", format="$,.0f"),
            ],
        )
    )
    st.altair_chart(gaming_chart, width="stretch")

# --- Airport passengers ---
st.subheader("Airport passengers (Harry Reid International)")
ap = line_of("%En/Deplaned Passengers%", "Passengers", "#7048e8")
if ap is not None:
    st.altair_chart(ap, width="stretch")

st.divider()

# --- Metric explorer ---
st.subheader("Explore any indicator")
metrics = query(
    "select distinct metric from main.mart_lvcva_indicators order by metric"
)["metric"].tolist()
choice = st.selectbox("Indicator", metrics)
detail = query(
    f"""
    select indicator_month, value
    from main.mart_lvcva_indicators
    where metric = '{choice.replace("'", "''")}'
    order by indicator_month
    """
)
detail_chart = (
    alt.Chart(detail)
    .mark_line(point=True, color="#0c8599")
    .encode(
        x=alt.X("indicator_month:T", title=None),
        y=alt.Y("value:Q", title=choice, scale=alt.Scale(zero=False)),
        tooltip=[
            alt.Tooltip("indicator_month:T", title="Month"),
            alt.Tooltip("value:Q", title="Value", format=",.2f"),
        ],
    )
)
st.altair_chart(detail_chart, width="stretch")
