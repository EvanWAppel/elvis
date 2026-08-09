"""City of Las Vegas parks — map and roster, filterable by council ward."""

import pydeck as pdk
import streamlit as st

from app_db import query

st.title("🌳 Parks")
st.caption("The City of Las Vegas park system — mapped by centroid and filterable by ward.")

df = query(
    """
    select
        park_name,
        address,
        status,
        public_access,
        ward,
        acres,
        park_type,
        amenities,
        latitude,
        longitude
    from main.mart_parks
    """
)
df["ward"] = df["ward"].fillna("Unassigned")

# --- Sidebar filter ---
st.sidebar.header("Filters")
wards = sorted(df["ward"].unique())
selected = st.sidebar.multiselect("Ward", wards, default=wards)
filtered = df[df["ward"].isin(selected)]

c1, c2 = st.columns(2)
c1.metric("Parks", f"{len(filtered):,}")
c2.metric("Total acreage", f"{filtered['acres'].sum():,.0f}")

if filtered.empty:
    st.info("No parks match the selected wards.")
    st.stop()

# --- Map (radius scaled by acreage) ---
filtered = filtered.copy()
filtered["radius"] = (filtered["acres"].clip(lower=1) ** 0.5) * 25
layer = pdk.Layer(
    "ScatterplotLayer",
    data=filtered,
    get_position=["longitude", "latitude"],
    get_radius="radius",
    get_fill_color=[46, 139, 87, 160],
    pickable=True,
)
view_state = pdk.ViewState(
    latitude=filtered["latitude"].mean(),
    longitude=filtered["longitude"].mean(),
    zoom=10,
    pitch=0,
)
tooltip = {
    "html": "<b>{park_name}</b><br/>{address}<br/>{acres} acres<br/>{amenities}",
    "style": {"backgroundColor": "seagreen", "color": "white", "fontSize": "13px"},
}
st.pydeck_chart(pdk.Deck(layers=[layer], initial_view_state=view_state, tooltip=tooltip))

# --- Table ---
st.subheader(f"Parks ({len(filtered)})")
st.dataframe(
    filtered[["park_name", "address", "ward", "acres", "park_type", "amenities", "status"]]
    .sort_values("acres", ascending=False),
    width="stretch",
    hide_index=True,
)
