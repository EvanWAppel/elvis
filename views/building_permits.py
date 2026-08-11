"""City of Las Vegas building permits — volume and valuation over time."""

import altair as alt
import streamlit as st

from app_db import query

st.title("🏗️ Building Permits")
st.caption(
    "City of Las Vegas archived building-permit history, with construction "
    "valuations. Great for spotting the valley's building cycles."
)

# --- KPIs ---
kpi = query(
    """
    select
        sum(permit_count)     as permits,
        sum(total_valuation)  as valuation
    from main.mart_permits_monthly
    """
)
span = query(
    "select min(issue_month) as first, max(issue_month) as last from main.mart_permits_monthly"
)
c1, c2, c3 = st.columns(3)
c1.metric("Permits issued", f"{int(kpi['permits'][0]):,}")
c2.metric("Total valuation", f"${kpi['valuation'][0] / 1e9:.1f}B")
c3.metric("Period", f"{span['first'][0]:%Y} – {span['last'][0]:%Y}")

st.divider()

# --- Monthly permits + valuation ---
monthly = query(
    """
    select issue_month, permit_count, total_valuation
    from main.mart_permits_monthly
    order by 1
    """
)
st.subheader("Permits issued per month")
permits_line = (
    alt.Chart(monthly)
    .mark_area(color="#3f88c5", opacity=0.7)
    .encode(
        x=alt.X("issue_month:T", title=None),
        y=alt.Y("permit_count:Q", title="Permits"),
        tooltip=[
            alt.Tooltip("issue_month:T", title="Month"),
            alt.Tooltip("permit_count:Q", title="Permits", format=","),
        ],
    )
)
st.altair_chart(permits_line, width="stretch")

st.subheader("Construction valuation per month")
val_line = (
    alt.Chart(monthly)
    .mark_line(color="#2e8b57")
    .encode(
        x=alt.X("issue_month:T", title=None),
        y=alt.Y("total_valuation:Q", title="Valuation ($)", axis=alt.Axis(format="~s")),
        tooltip=[
            alt.Tooltip("issue_month:T", title="Month"),
            alt.Tooltip("total_valuation:Q", title="Valuation", format="$,.0f"),
        ],
    )
)
st.altair_chart(val_line, width="stretch")

# --- By type ---
by_type = query(
    """
    select application_type, permit_count, total_valuation
    from main.mart_permits_by_type
    order by permit_count desc
    limit 15
    """
)
st.subheader("Permits by application type")
type_chart = (
    alt.Chart(by_type)
    .mark_bar(color="#3f88c5")
    .encode(
        x=alt.X("permit_count:Q", title="Permits"),
        y=alt.Y("application_type:N", sort="-x", title=None),
        tooltip=[
            "application_type",
            alt.Tooltip("permit_count:Q", title="Permits", format=","),
            alt.Tooltip("total_valuation:Q", title="Valuation", format="$,.0f"),
        ],
    )
)
st.altair_chart(type_chart, width="stretch")
st.dataframe(by_type, width="stretch", hide_index=True)

st.divider()

# --- Henderson permits (counts only — the Henderson feed carries no valuation) ---
st.header("🏙️ Henderson permits")
st.caption(
    "City of Henderson building permits. Henderson's feed has no valuation, so "
    "this is by permit count — but it runs to the present, unlike the archived "
    "Las Vegas series above."
)
hen_monthly = query(
    """
    select issue_month, sum(permit_count) as permit_count
    from main.mart_henderson_permits
    group by 1
    order by 1
    """
)
hen_line = (
    alt.Chart(hen_monthly)
    .mark_area(color="#e8590c", opacity=0.7)
    .encode(
        x=alt.X("issue_month:T", title=None),
        y=alt.Y("permit_count:Q", title="Permits"),
        tooltip=[
            alt.Tooltip("issue_month:T", title="Month"),
            alt.Tooltip("permit_count:Q", title="Permits", format=","),
        ],
    )
)
st.altair_chart(hen_line, width="stretch")

hen_types = query(
    """
    select case_type, sum(permit_count) as permit_count
    from main.mart_henderson_permits
    group by 1
    order by permit_count desc
    limit 12
    """
)
hen_type_chart = (
    alt.Chart(hen_types)
    .mark_bar(color="#e8590c")
    .encode(
        x=alt.X("permit_count:Q", title="Permits"),
        y=alt.Y("case_type:N", sort="-x", title=None),
        tooltip=["case_type", alt.Tooltip("permit_count:Q", title="Permits", format=",")],
    )
)
st.altair_chart(hen_type_chart, width="stretch")
