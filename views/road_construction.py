"""Road construction across the metro — Capital Improvement + state-route work."""

import json

import pandas as pd
import pydeck as pdk
import streamlit as st

from app_db import query

st.title("🚧 Road Construction")
st.caption(
    "Where the metro is under construction: City of Las Vegas Capital Improvement "
    "Program projects (streets, sewer, safety) and — when a Nevada 511 key is "
    "configured — NDOT state-route roadwork and closures. Each line is the project "
    "extent; color marks the phase."
)

df = query(
    """
    select
        data_source, project_name, description, status, category, road_name,
        extent, contractor, url, path_json, latitude, longitude,
        cast(start_date as varchar) as start_date,
        cast(end_date   as varchar) as end_date
    from main.mart_road_construction
    """
)

if df.empty:
    st.info("No road construction data in the warehouse yet.")
    st.stop()

df["path"] = df["path_json"].apply(json.loads)
df["status"] = df["status"].fillna("Unknown")

# --- Sidebar filters ---
st.sidebar.header("Filters")
sources = sorted(df["data_source"].unique())
sel_sources = st.sidebar.multiselect("Source", sources, default=sources)
statuses = sorted(df["status"].unique())
sel_status = st.sidebar.multiselect("Status / phase", statuses, default=statuses)
current_only = st.sidebar.checkbox(
    "Current only (hide closed & past projects)", value=True
)
active_only = st.sidebar.checkbox("Only active construction", value=False)

filtered = df[df["data_source"].isin(sel_sources) & df["status"].isin(sel_status)]
# "Current" = not in a Closed phase and not already past its end date.
if current_only:
    end_dt = pd.to_datetime(filtered["end_date"], errors="coerce")
    today = pd.Timestamp.now().normalize()
    is_stale = filtered["status"].str.contains("closed", case=False, na=False) | (
        end_dt.notna() & (end_dt < today)
    )
    filtered = filtered[~is_stale]
# "Active" = CLV projects in the Construction phase, or any live 511 roadwork event.
active_mask = filtered["status"].str.contains("construction", case=False, na=False) | (
    filtered["data_source"].str.startswith("NDOT")
)
if active_only:
    filtered = filtered[active_mask]

if filtered.empty:
    st.info("No projects match the current filters.")
    st.stop()

c1, c2, c3 = st.columns(3)
c1.metric("Projects", f"{len(filtered):,}")
c2.metric("Actively under construction", f"{int(active_mask[filtered.index].sum()):,}")
c3.metric("Corridors (named roads)", f"{filtered['road_name'].nunique():,}")

# --- Map: color by phase, active work highlighted orange ---
PALETTE = {
    "construction": [255, 111, 0, 220],  # active — orange
    "bidding": [255, 179, 0, 200],
    "design": [30, 136, 229, 190],
    "pre-design": [30, 136, 229, 140],
    "planned": [120, 144, 156, 170],
    "closed": [120, 144, 156, 90],
}


def phase_color(status: str) -> list[int]:
    key = (status or "").lower()
    for name, color in PALETTE.items():
        if name in key:
            return color
    return [120, 144, 156, 150]


filtered = filtered.copy()
filtered["color"] = filtered["status"].apply(phase_color)

path_layer = pdk.Layer(
    "PathLayer",
    data=filtered,
    get_path="path",
    get_color="color",
    get_width=5,
    width_min_pixels=3,
    width_scale=20,
    cap_rounded=True,
    joint_rounded=True,
    pickable=True,
)
# A dot at each centroid so short/point-only features stay clickable.
point_layer = pdk.Layer(
    "ScatterplotLayer",
    data=filtered,
    get_position=["longitude", "latitude"],
    get_fill_color="color",
    get_radius=45,
    radius_min_pixels=2,
    pickable=True,
)
view_state = pdk.ViewState(
    latitude=filtered["latitude"].mean(),
    longitude=filtered["longitude"].mean(),
    zoom=10.5,
    pitch=0,
)
tooltip = {
    "html": (
        "<b>{project_name}</b><br/>{road_name}<br/>{extent}<br/>"
        "<i>{status}</i> · {data_source}<br/>{start_date} → {end_date}"
    ),
    "style": {"backgroundColor": "#263238", "color": "white", "fontSize": "12px"},
}
st.pydeck_chart(
    pdk.Deck(
        layers=[path_layer, point_layer],
        initial_view_state=view_state,
        map_style="https://basemaps.cartocdn.com/gl/positron-gl-style/style.json",
        tooltip=tooltip,
    )
)
st.caption("🟠 under construction · 🔵 design · ⚪ planned / closed")

# --- Table ---
st.subheader(f"Projects ({len(filtered)})")
st.dataframe(
    filtered[
        [
            "project_name", "data_source", "status", "road_name", "extent",
            "start_date", "end_date", "contractor",
        ]
    ].sort_values(["data_source", "status", "project_name"]),
    width="stretch",
    hide_index=True,
)
