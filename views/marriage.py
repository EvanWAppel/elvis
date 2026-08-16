"""Clark County marriage licenses — the wedding capital, by the numbers."""

import altair as alt
import streamlit as st

from app_db import query

st.title("💍 Marriage Licenses")
st.caption(
    "Clark County marriage licenses (2007–2024). Las Vegas is the wedding "
    "capital of the world — the spikes and seasonality show why."
)

# --- KPIs ---
kpi = query(
    """
    select
        sum(license_count)                     as total,
        min(license_month)                     as first_month,
        max(license_month)                     as last_month
    from main.mart_marriage_monthly
    """
)
peak = query(
    "select license_date, license_count from main.mart_marriage_daily order by license_count desc limit 1"
)
c1, c2, c3 = st.columns(3)
c1.metric("Licenses issued", f"{int(kpi['total'][0]):,}")
c2.metric(
    "Period", f"{kpi['first_month'][0]:%Y} – {kpi['last_month'][0]:%Y}"
)
c3.metric(
    "Busiest single day",
    f"{int(peak['license_count'][0]):,}",
    help=f"{peak['license_date'][0]:%b %d, %Y}",
)

st.divider()

# --- Monthly trend ---
monthly = query(
    "select license_month, license_count from main.mart_marriage_monthly order by 1"
)
st.subheader("Licenses per month")
st.caption("Note the long decline, the 2020 pandemic collapse, and the recovery.")
trend = (
    alt.Chart(monthly)
    .mark_line(color="#d6336c")
    .encode(
        x=alt.X("license_month:T", title=None),
        y=alt.Y("license_count:Q", title="Licenses"),
        tooltip=[
            alt.Tooltip("license_month:T", title="Month"),
            alt.Tooltip("license_count:Q", title="Licenses", format=","),
        ],
    )
)
st.altair_chart(trend, width="stretch")

# --- Biggest single days (novelty dates) ---
big_days = query(
    """
    select license_date, license_count
    from main.mart_marriage_daily
    order by license_count desc
    limit 15
    """
)
big_days["label"] = big_days["license_date"].dt.strftime("%b %d, %Y")
st.subheader("Biggest single days")
st.caption("Valentine's Day, New Year's Eve, and novelty dates like 07/07/07 and 12/12/12.")
days_chart = (
    alt.Chart(big_days)
    .mark_bar(color="#d6336c")
    .encode(
        x=alt.X("license_count:Q", title="Licenses issued"),
        y=alt.Y("label:N", sort="-x", title=None),
        tooltip=["label", alt.Tooltip("license_count:Q", title="Licenses", format=",")],
    )
)
st.altair_chart(days_chart, width="stretch")

col_a, col_b = st.columns(2)

# --- Where couples come from ---
with col_a:
    origin = query(
        """
        select origin, license_count
        from main.mart_marriage_by_origin
        where origin <> 'UNKNOWN'
        order by license_count desc
        limit 12
        """
    )
    st.subheader("Where couples come from")
    origin_chart = (
        alt.Chart(origin)
        .mark_bar(color="#ae3ec9")
        .encode(
            x=alt.X("license_count:Q", title="Licenses"),
            y=alt.Y("origin:N", sort="-x", title=None),
            tooltip=["origin", alt.Tooltip("license_count:Q", title="Licenses", format=",")],
        )
    )
    st.altair_chart(origin_chart, width="stretch")

# --- Same-sex vs different-sex ---
with col_b:
    gender = query(
        """
        select license_year, couple_type, license_count
        from main.mart_marriage_by_gender_year
        order by license_year
        """
    )
    st.subheader("Same-sex vs different-sex")
    st.caption("Nevada began issuing same-sex licenses in October 2014.")
    gender_chart = (
        alt.Chart(gender)
        .mark_area()
        .encode(
            x=alt.X("license_year:O", title=None),
            y=alt.Y("license_count:Q", title="Licenses", stack="normalize"),
            color=alt.Color("couple_type:N", title=None),
            tooltip=[
                "license_year",
                "couple_type",
                alt.Tooltip("license_count:Q", title="Licenses", format=","),
            ],
        )
    )
    st.altair_chart(gender_chart, width="stretch")
