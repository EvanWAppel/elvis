"""Restaurant inspections — Southern Nevada Health District, Clark County-wide."""

import altair as alt
import pandas as pd
import streamlit as st

from app_db import query


def _sql_literal(value: str) -> str:
    """Escape a value for safe inline use in a single-quoted SQL literal."""
    return str(value).replace("'", "''")


st.title("🍽️ Restaurant Inspections")
st.caption(
    "Southern Nevada Health District inspections covering **all of Clark "
    "County**, sourced nightly from SNHD's developer data feed. Includes "
    "establishment names, addresses, and inspection history from 2020 to present."
)

# --- KPIs ---
kpi = query(
    """
    select
        sum(total_inspections)      as inspections,
        count(*)                    as restaurants,
        round(avg(avg_demerits), 2) as avg_demerits
    from main.mart_restaurants
    """
)
c1, c2, c3 = st.columns(3)
c1.metric("Inspections on record", f"{int(kpi['inspections'][0]):,}")
c2.metric("Establishments", f"{int(kpi['restaurants'][0]):,}")
c3.metric("Avg demerits / inspection", f"{kpi['avg_demerits'][0]:.2f}")

st.divider()

# --- Restaurants (sortable + selectable) ---
st.subheader("Restaurants")
st.caption(
    "Every establishment on file with the SNHD, with its current grade and "
    "inspection history. Click a column header to sort, type to filter by name, "
    "and **select a row to drill into its inspection history**."
)
restaurants = query(
    """
    select
        permit_number,
        restaurant_name,
        address,
        city_name,
        zip_code,
        current_grade,
        current_demerits,
        date_current,
        total_inspections,
        avg_demerits,
        worst_demerits,
        first_inspection,
        last_inspection,
        failed_inspections,
        downgrades,
        closures,
        failure_rate_pct,
        status
    from main.mart_restaurants
    order by total_inspections desc, restaurant_name
    """
)
name_filter = st.text_input("Filter by name", placeholder="e.g. McDonald's")
view = restaurants
if name_filter:
    view = view[
        view["restaurant_name"].str.contains(name_filter, case=False, na=False)
    ].reset_index(drop=True)
st.caption(f"Showing {len(view):,} of {len(restaurants):,} establishments")
event = st.dataframe(
    view,
    width="stretch",
    hide_index=True,
    on_select="rerun",
    selection_mode="single-row",
    key="restaurant_table",
    column_order=[
        "restaurant_name", "address", "city_name", "zip_code",
        "current_grade", "current_demerits", "date_current",
        "total_inspections", "avg_demerits", "worst_demerits",
        "first_inspection", "last_inspection",
        "failed_inspections", "downgrades", "closures", "failure_rate_pct",
        "status",
    ],
    column_config={
        "restaurant_name": "Restaurant",
        "address": "Address",
        "city_name": "City",
        "zip_code": "ZIP",
        "current_grade": "Grade",
        "current_demerits": st.column_config.NumberColumn("Current demerits"),
        "date_current": st.column_config.DateColumn("Grade date"),
        "total_inspections": st.column_config.NumberColumn("Inspections"),
        "avg_demerits": st.column_config.NumberColumn("Avg demerits", format="%.1f"),
        "worst_demerits": st.column_config.NumberColumn("Worst demerits"),
        "first_inspection": st.column_config.DateColumn("First inspection"),
        "last_inspection": st.column_config.DateColumn("Last inspection"),
        "failed_inspections": st.column_config.NumberColumn("Failed"),
        "downgrades": st.column_config.NumberColumn("Downgrades"),
        "closures": st.column_config.NumberColumn("Closures"),
        "failure_rate_pct": st.column_config.NumberColumn(
            "Failure rate", format="%.1f%%"
        ),
        "status": "Status",
    },
)

# --- Drill-down: selected restaurant's history + violations ---
selected = event.selection.rows
if not selected:
    st.info(
        "Select a restaurant above to see its full inspection history and the "
        "specific violations cited."
    )
else:
    r = view.iloc[selected[0]]
    permit = _sql_literal(r["permit_number"])
    grade = r["current_grade"] if pd.notna(r["current_grade"]) else "N/A"
    worst = int(r["worst_demerits"]) if pd.notna(r["worst_demerits"]) else None

    st.markdown(f"### {r['restaurant_name']}")
    st.caption(
        f"{r['address']} · {r['city_name']} {r['zip_code']} · "
        f"Permit {r['permit_number']}"
    )
    d1, d2, d3, d4 = st.columns(4)
    d1.metric("Current grade", grade)
    d2.metric("Inspections", int(r["total_inspections"]))
    d3.metric("Failed inspections", int(r["failed_inspections"]))
    d4.metric("Worst demerits", "—" if worst is None else worst)

    history = query(
        f"""
        select
            serial_number,
            inspection_date,
            inspection_type,
            inspection_grade,
            inspection_result,
            inspection_demerits,
            violation_count
        from main.mart_inspection_history
        where permit_number = '{permit}'
        order by inspection_date desc
        """
    )

    if history.empty:
        st.caption("No inspections on record for this establishment.")
    else:
        st.markdown("**Inspection history**")
        st.caption("Select an inspection to see the specific violations cited.")
        hist_event = st.dataframe(
            history,
            width="stretch",
            hide_index=True,
            on_select="rerun",
            selection_mode="single-row",
            key=f"history_{r['permit_number']}",
            column_order=[
                "inspection_date", "inspection_type", "inspection_grade",
                "inspection_result", "inspection_demerits", "violation_count",
            ],
            column_config={
                "inspection_date": st.column_config.DateColumn("Date"),
                "inspection_type": "Type",
                "inspection_grade": "Grade",
                "inspection_result": "Result",
                "inspection_demerits": st.column_config.NumberColumn("Demerits"),
                "violation_count": st.column_config.NumberColumn("Violations"),
            },
        )

        hist_selected = hist_event.selection.rows
        if hist_selected and hist_selected[0] < len(history):
            h = history.iloc[hist_selected[0]]
            serial = _sql_literal(h["serial_number"])
            when = pd.to_datetime(h["inspection_date"]).strftime("%b %d, %Y")
            st.markdown(
                f"**Violations cited — {when} · {h['inspection_type']} · "
                f"{h['inspection_result']} ({int(h['inspection_demerits'])} demerits)**"
            )
            violations = query(
                f"""
                select
                    violation_code,
                    coalesce(violation_description, 'Code ' || violation_code)
                        as violation_description,
                    violation_demerits
                from main.mart_inspection_violations
                where serial_number = '{serial}'
                order by violation_demerits desc nulls last
                """
            )
            if violations.empty:
                st.caption("No violations recorded for this inspection.")
            else:
                st.dataframe(
                    violations,
                    width="stretch",
                    hide_index=True,
                    column_config={
                        "violation_code": "Code",
                        "violation_description": "Violation",
                        "violation_demerits": st.column_config.NumberColumn(
                            "Demerits"
                        ),
                    },
                )

st.divider()

# --- Current grade distribution ---
st.subheader("Current grade distribution")
st.caption("Current grade per establishment. **A** is best (fewest demerits).")
grades = query(
    """
    select
        coalesce(nullif(current_grade, ''), 'N/A') as grade,
        count(*)                                   as restaurants
    from main.mart_restaurants
    group by 1
    order by restaurants desc
    """
)
grade_chart = (
    alt.Chart(grades)
    .mark_bar(color="#ff2e88")
    .encode(
        x=alt.X("grade:N", sort="-y", title="Grade"),
        y=alt.Y("restaurants:Q", title="Establishments"),
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
        coalesce(any_value(violation_description), 'Code ' || violation_code) as description,
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
start, end = st.slider("Year range", lo, hi, (lo, hi))
mask = (years >= start) & (years <= end)
st.line_chart(
    compliance[mask].set_index("inspection_month")["compliance_pct"],
    y_label="Compliant inspections (%)",
)
st.caption(
    "Share of passing inspections (an \"A\" grade) by month, SNHD data from "
    "2020 onward."
)
