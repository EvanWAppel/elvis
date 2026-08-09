"""Public art map — City of Las Vegas collection, filterable by council ward."""

import pandas as pd
import pydeck as pdk
import streamlit as st

from app_db import query

st.title("🗺️ City of Las Vegas Public Art")
st.caption("The City's public art collection — geocoded and filterable by council ward.")

df = query(
    """
    select
        "ObjectId"  as objectid,
        artwork_name,
        artist,
        medium,
        location_detail,
        address,
        ward,
        latitude,
        longitude,
        "PIC_URL"   as pic_url,
        "THUMB_URL" as thumb_url
    from main.mart_art_work_points
    """
)

# A handful of pieces (UNLV campus, county-located) have no council ward;
# bucket them as "Other" so they stay filterable and visible on the map.
df["ward"] = df["ward"].replace("", pd.NA).fillna("Other")

# --- Sidebar filter ---
st.sidebar.header("Filters")
wards = sorted(df["ward"].unique())
selected_wards = st.sidebar.multiselect("Ward", wards, default=wards)

filtered = df[df["ward"].isin(selected_wards)]

if filtered.empty:
    st.info("No artworks match the selected wards — pick at least one ward.")
    st.stop()

# --- Map ---
layer = pdk.Layer(
    "ScatterplotLayer",
    data=filtered,
    get_position=["longitude", "latitude"],
    get_radius=50,
    get_fill_color=[255, 100, 0, 180],
    pickable=True,
)
view_state = pdk.ViewState(
    latitude=filtered["latitude"].mean(),
    longitude=filtered["longitude"].mean(),
    zoom=12,
    pitch=0,
)
tooltip = {
    "html": "<b>{artwork_name}</b><br/>{artist}<br/><i>{medium}</i><br/>{address}",
    "style": {"backgroundColor": "steelblue", "color": "white", "fontSize": "13px"},
}
st.pydeck_chart(
    pdk.Deck(layers=[layer], initial_view_state=view_state, tooltip=tooltip)
)

# --- Detail panel ---
st.subheader(f"Artworks ({len(filtered)})")
selected = st.selectbox(
    "Select an artwork to preview", filtered["artwork_name"].sort_values()
)
row = filtered[filtered["artwork_name"] == selected].iloc[0]

col1, col2 = st.columns([1, 2])
with col1:
    if pd.notna(row["pic_url"]):
        st.image(row["pic_url"], width="stretch")
with col2:
    st.markdown(f"**Artist:** {row['artist']}")
    st.markdown(f"**Medium:** {row['medium']}")
    st.markdown(f"**Location:** {row['location_detail']}")
    st.markdown(f"**Address:** {row['address']}")
    st.markdown(f"**Ward:** {row['ward']}")
