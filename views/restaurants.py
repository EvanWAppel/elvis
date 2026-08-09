"""Restaurant inspections — Southern Nevada Health District, Clark County-wide."""

import altair as alt
import streamlit as st

from app_db import query

st.title("🍽️ Restaurant Inspections")
st.caption(
    "Southern Nevada Health District — covering **all of Clark County**. The "
    "public open-data feed carries inspection facts only (no restaurant names or "
    "addresses), so this page is the county-wide analytics view."
)

# --- KPIs ---
kpi = query(
    """
    select
        sum(total_inspections)      as inspections,
        count(*)                    as restaurants,
        round(avg(avg_demerits), 2) as avg_demerits
    from main.mart_restaurant_grades
    """
)
c1, c2, c3 = st.columns(3)
c1.metric("Inspections on record", f"{int(kpi['inspections'][0]):,}")
c2.metric("Restaurants", f"{int(kpi['restaurants'][0]):,}")
c3.metric("Avg demerits / inspection", f"{kpi['avg_demerits'][0]:.2f}")

st.divider()

# --- Current grade distribution ---
st.subheader("Current grade distribution")
st.caption("Most recent grade per restaurant. **A** is best (fewest demerits).")
grades = query(
    """
    select
        coalesce(nullif(latest_grade, ''), 'N/A') as grade,
        count(*)                                  as restaurants
    from main.mart_restaurant_grades
    group by 1
    order by restaurants desc
    """
)
grade_chart = (
    alt.Chart(grades)
    .mark_bar(color="#ff2e88")
    .encode(
        x=alt.X("grade:N", sort="-y", title="Grade"),
        y=alt.Y("restaurants:Q", title="Restaurants"),
        tooltip=["grade", "restaurants"],
    )
)
st.altair_chart(grade_chart, width="stretch")

# --- Top violations ---
st.subheader("Top 20 violations (county-wide)")
top_violations = query(
    """
    select
        violation_code,
        coalesce(any_value("Violation_Description"), 'Code ' || violation_code) as description,
        sum(occurrence_count) as occurrences
    from main.mart_top_violations
    group by 1
    order by occurrences desc
    limit 20
    """
)
top_violations["label"] = top_violations["description"].str.slice(0, 70)
violations_chart = (
    alt.Chart(top_violations)
    .mark_bar(color="#00e0ff")
    .encode(
        x=alt.X("occurrences:Q", title="Occurrences"),
        y=alt.Y("label:N", sort="-x", title=None),
        tooltip=["violation_code", "description", "occurrences"],
    )
)
st.altair_chart(violations_chart, width="stretch")

# --- Compliance over time ---
st.subheader("Compliance rate over time")
compliance = query(
    """
    select
        inspection_month,
        sum(compliant_count)::bigint     as compliant,
        sum(non_compliant_count)::bigint as non_compliant
    from main.mart_inspections_over_time
    group by 1
    order by inspection_month
    """
)
compliance["total"] = compliance["compliant"] + compliance["non_compliant"]
compliance["compliance_pct"] = (
    compliance["compliant"] / compliance["total"] * 100
).round(1)

years = compliance["inspection_month"].dt.year
lo, hi = int(years.min()), int(years.max())
start, end = st.slider("Year range", lo, hi, (max(lo, 2005), hi))
mask = (years >= start) & (years <= end)
st.line_chart(
    compliance[mask].set_index("inspection_month")["compliance_pct"],
    y_label="Compliant inspections (%)",
)
st.caption(
    "Share of inspections with a Compliant result, by month. Early years carry "
    "lower inspection volume."
)
