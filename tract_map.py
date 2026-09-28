"""Interactive area comparisons shared by the calls page and the tract explorer."""

import json

import pandas as pd
import pydeck as pdk
import streamlit as st

from app_db import query
from choropleth import map_features
from ui import MAP_STYLE

TOPIC_LABELS = {
    "calls": "LVMPD calls for service",
    "henderson_crime": "Henderson crime reports",
    "parks": "Park records",
    "rentals": "Short-term rental registrations",
    "public_art": "Public artworks",
}
TOPIC_NOTES = {
    "calls": "LVMPD records are not complete Henderson or North Las Vegas police coverage. "
    "Counts are source call records, not confirmed crimes or individual risk.",
    "henderson_crime": "City of Henderson crime *reports* — a different measure from LVMPD "
    "calls for service; the two are never combined. Henderson only; counts are source report "
    "records for recent years, not annualized and not comparable to call volumes. Annual "
    "report volumes differ, so no per-resident rate is offered.",
    "parks": "Published park inventories; a park is assigned using its source point/centroid. "
    "Counts do not measure acreage or access.",
    "rentals": "Published registrations across all statuses; city licensing definitions differ. "
    "Counts are not a census of operating rental properties.",
    "public_art": "Las Vegas and Henderson collections. A North Las Vegas public-art feed "
    "has not been verified; absence of coverage does not mean no artworks.",
}


def render_tract_map(topic: str, *, key: str):
    if topic not in TOPIC_LABELS:
        raise ValueError("Unknown tract topic")
    rows = query("select * from main.mart_tract_metrics")
    rows = rows.loc[rows.topic == topic].copy()
    st.caption(TOPIC_NOTES[topic])
    if rows.empty:
        st.info("No tract snapshot is available for this topic.")
        return
    city_options = sorted(
        {city for value in rows.cities_json for city in json.loads(value)}
    )
    # Default to the complete mapped footprint, including gray coverage gaps.
    cities = st.multiselect(
        "Cities / areas (whole intersecting tracts)",
        city_options,
        default=city_options,
        key=f"{key}_cities",
    )
    metrics = ["Count"]
    if rows.rate_per_1000.notna().any():
        metrics.append("Per 1,000 residents (2020 Census)")
    choice = st.radio("Map value", metrics, horizontal=True, key=f"{key}_metric")
    metric = "record_count" if choice == "Count" else "rate_per_1000"
    features, maximum = map_features(rows, metric, cities)
    st.caption(
        "City selection shows whole intersecting tracts, including portions outside the "
        "selected city. Values and colors stay comparable when cities are filtered. "
        "These are tract totals, not city totals."
    )
    if not features:
        st.info("Select at least one city or area to display its tracts.")
        return
    periods = " · ".join(sorted(rows.period.dropna().unique()))
    st.caption(
        f"Period: {periods}. Boundary and population vintage: 2020 Census. "
        "Rates use the full reporting period and are not annualized."
    )
    layer = pdk.Layer(
        "GeoJsonLayer",
        id="tracts",
        data={"type": "FeatureCollection", "features": features},
        filled=True,
        stroked=True,
        extruded=False,
        pickable=True,
        get_fill_color="properties.fill",
        get_line_color=[180, 176, 196, 130],
        line_width_min_pixels=1,
        auto_highlight=True,
    )
    deck = pdk.Deck(
        layers=[layer],
        map_style=MAP_STYLE,
        initial_view_state=pdk.ViewState(
            latitude=36.12, longitude=-115.12, zoom=9, pitch=0
        ),
        tooltip={
            "text": "{tract_name} ({geoid})\n{cities}\nValue: {value_label}\n"
            "Coverage: {coverage}\nPeriod: {period}\n"
            "2020 population: {population_label}"
        },
    )
    event = st.pydeck_chart(
        deck, on_select="rerun", selection_mode="single-object", key=key
    )
    st.markdown(
        f"🟣 **0** → 🟡 **{maximum:,.1f}** {choice.lower()} · "
        "Gray: no data / rate unavailable. Partial coverage values are observed records only."
    )
    st.caption(
        "“Available” means the source covers that footprint; it is not a guarantee "
        "of complete reporting. No-data tracts are never assigned a zero."
    )
    objects = []
    if event and "selection" in event:
        objects = (event["selection"].get("objects") or {}).get("tracts", [])
    if objects:
        properties = objects[0].get("properties", {})
        geoid = properties.get("geoid")
        visible_ids = {feature["properties"]["geoid"] for feature in features}
        selected = rows.loc[(rows.geoid == geoid) & rows.geoid.isin(visible_ids)]
        if not selected.empty:
            st.subheader(f"{selected.iloc[0].tract_name} — {geoid}")
            st.write(f"Coverage: {selected.iloc[0].coverage}")
            details = query(
                "select topic, geoid, category, record_count from main.stg_tract_counts"
            )
            details = details.loc[(details.topic == topic) & (details.geoid == geoid)]
            st.dataframe(
                details[["category", "record_count"]].sort_values(
                    "record_count", ascending=False
                ),
                hide_index=True,
                width="stretch",
            )
    else:
        st.caption("Select a tract to see its record breakdown.")
    audit = query("select * from main.mart_tract_assignment_audit")
    audit = audit.loc[audit.topic == topic]
    if not audit.empty:
        a = audit.iloc[0]
        st.caption(
            f"Assignment: {a.assigned_records:,.0f} mapped of {a.source_records:,.0f} source records; "
            f"{a.invalid_coordinates:,.0f} invalid/missing coordinates; "
            f"{a.outside_tracts:,.0f} outside mapped tracts; "
            f"{a.boundary_ties:,.0f} boundary/overlap ties assigned once to the lowest GEOID."
        )
    with st.expander("Tract values and coverage"):
        ids = {f["properties"]["geoid"] for f in features}
        display = rows.loc[
            rows.geoid.isin(ids),
            [
                "geoid",
                "tract_name",
                "record_count",
                "rate_per_1000",
                "coverage",
                "period",
            ],
        ]
        st.dataframe(
            display.replace({float("nan"): pd.NA}), hide_index=True, width="stretch"
        )
