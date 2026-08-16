"""Fire-prevention inspections — City of Las Vegas multi-unit residential."""

import altair as alt
import pydeck as pdk
import streamlit as st

from app_db import query

st.title("🔥 Fire-Prevention Inspections")
st.caption(
    "City of Las Vegas fire-prevention inspections of multi-unit residential "
    "properties. Note: the source dataset is no longer updated."
)

# --- KPIs ---
kpi = query(
    """
    select
        count(*)                                    as properties,
        sum(total_violations)                       as violations,
        round(avg(avg_pct_dwellings_with_violations), 1) as avg_pct
    from main.mart_fire_prevention_inspections
    """
)
c1, c2, c3 = st.columns(3)
c1.metric("Properties inspected", f"{int(kpi['properties'][0]):,}")
c2.metric("Total violations written", f"{int(kpi['violations'][0]):,}")
c3.metric("Avg % dwellings w/ violations", f"{kpi['avg_pct'][0]:.1f}%")

st.divider()

# --- Map of inspected properties ---
st.subheader("Inspected properties")
st.caption("Each dot is a property; size reflects unit count and color the violations written.")
mapped = query(
    """
    select
        property_name,
        "Address" as address,
        "City"    as city,
        unit_count,
        total_violations,
        latitude,
        longitude
    from main.mart_fire_prevention_inspections
    where latitude is not null and longitude is not null
    """
)
mapped = mapped.copy()
mapped["radius"] = (mapped["unit_count"].clip(lower=1) ** 0.5) * 12
# Red intensity scaled to each property's share of the worst violation count.
vmax = max(int(mapped["total_violations"].max()), 1)
mapped["fill"] = mapped["total_violations"].apply(
    lambda v: [230, max(30, int(200 - 200 * (v / vmax))), 30, 170]
)
layer = pdk.Layer(
    "ScatterplotLayer",
    data=mapped,
    get_position=["longitude", "latitude"],
    get_radius="radius",
    get_fill_color="fill",
    pickable=True,
)
view_state = pdk.ViewState(
    latitude=mapped["latitude"].mean(),
    longitude=mapped["longitude"].mean(),
    zoom=10.5,
    pitch=0,
)
tooltip = {
    "html": "<b>{property_name}</b><br/>{address}, {city}<br/>"
    "{unit_count} units · {total_violations} violations",
    "style": {"backgroundColor": "#b22222", "color": "white", "fontSize": "13px"},
}
st.pydeck_chart(
    pdk.Deck(
        layers=[layer],
        initial_view_state=view_state,
        map_style="https://basemaps.cartocdn.com/gl/positron-gl-style/style.json",
        tooltip=tooltip,
    )
)

st.divider()

# --- Worst offenders ---
worst = query(
    """
    select
        property_name,
        "Address" as address,
        "City"    as city,
        unit_count,
        total_violations,
        avg_pct_dwellings_with_violations as avg_pct_dwellings
    from main.mart_fire_prevention_inspections
    order by total_violations desc nulls last
    limit 20
    """
)

st.subheader("Worst offenders")
st.caption("Properties with the most fire-prevention violations written, all-time.")
top15 = worst.head(15)
worst_chart = (
    alt.Chart(top15)
    .mark_bar(color="#ffbf3f")
    .encode(
        x=alt.X("total_violations:Q", title="Total violations"),
        y=alt.Y("property_name:N", sort="-x", title=None),
        tooltip=["property_name", "address", "unit_count", "total_violations"],
    )
)
st.altair_chart(worst_chart, width="stretch")

st.dataframe(worst, width="stretch", hide_index=True)
