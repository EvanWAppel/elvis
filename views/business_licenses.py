"""City of Las Vegas business licenses — what kinds of businesses, and where."""

import altair as alt
import streamlit as st

from app_db import query

st.title("📋 Business Licenses")
st.caption("The City of Las Vegas business-license registry — searchable and broken down by type.")

# --- KPIs ---
kpi = query(
    """
    select
        count(*)                                          as licenses,
        sum(case when lower(status) = 'active' then 1 else 0 end) as active,
        count(distinct type_of_business)                  as types
    from main.mart_business_licenses
    """
)
c1, c2, c3 = st.columns(3)
c1.metric("Licenses on file", f"{int(kpi['licenses'][0]):,}")
c2.metric("Active", f"{int(kpi['active'][0]):,}")
c3.metric("Business types", f"{int(kpi['types'][0]):,}")

st.divider()

# --- Top business types ---
by_type = query(
    """
    select type_of_business, license_count, active_count
    from main.mart_licenses_by_type
    order by license_count desc
    limit 20
    """
)
st.subheader("Most common business types")
type_chart = (
    alt.Chart(by_type)
    .mark_bar(color="#6a4c93")
    .encode(
        x=alt.X("license_count:Q", title="Licenses"),
        y=alt.Y("type_of_business:N", sort="-x", title=None),
        tooltip=[
            "type_of_business",
            alt.Tooltip("license_count:Q", title="Licenses", format=","),
            alt.Tooltip("active_count:Q", title="Active", format=","),
        ],
    )
)
st.altair_chart(type_chart, width="stretch")

st.divider()

# --- Searchable table ---
st.subheader("Search licenses")
search = st.text_input("Filter by business name or type", "")
where = ""
if search:
    safe = search.replace("'", "''")
    where = (
        f"where business_name ilike '%{safe}%' or type_of_business ilike '%{safe}%'"
    )
rows = query(
    f"""
    select business_name, type_of_business, status, zip_code, within_city_limits
    from main.mart_business_licenses
    {where}
    order by business_name
    limit 500
    """
)
st.caption(f"Showing up to 500 rows ({len(rows)} shown).")
st.dataframe(rows, width="stretch", hide_index=True)

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
