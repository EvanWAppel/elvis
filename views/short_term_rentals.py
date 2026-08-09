"""City of Las Vegas short-term rental licenses — map and roster."""

import pydeck as pdk
import streamlit as st

from app_db import query

st.title("🏠 Short-Term Rentals")
st.caption("Licensed short-term rentals (Airbnb-style) within City of Las Vegas limits.")

df = query(
    """
    select
        license_no,
        business_name,
        business_type,
        category,
        license_status,
        address,
        latitude,
        longitude
    from main.mart_short_term_rentals
    """
)

# --- Sidebar filter ---
st.sidebar.header("Filters")
statuses = sorted(df["license_status"].dropna().unique())
selected = st.sidebar.multiselect("License status", statuses, default=statuses)
filtered = df[df["license_status"].isin(selected)]

c1, c2 = st.columns(2)
c1.metric("Licensed rentals", f"{len(filtered):,}")
c2.metric("Active", f"{(filtered['license_status'].str.lower() == 'active').sum():,}")

if filtered.empty:
    st.info("No rentals match the selected statuses.")
    st.stop()

# --- Map ---
layer = pdk.Layer(
    "ScatterplotLayer",
    data=filtered,
    get_position=["longitude", "latitude"],
    get_radius=80,
    get_fill_color=[106, 76, 147, 180],
    pickable=True,
)
view_state = pdk.ViewState(
    latitude=filtered["latitude"].mean(),
    longitude=filtered["longitude"].mean(),
    zoom=11,
    pitch=0,
)
tooltip = {
    "html": "<b>{business_name}</b><br/>{business_type}<br/>{address}<br/>{license_status}",
    "style": {"backgroundColor": "steelblue", "color": "white", "fontSize": "13px"},
}
st.pydeck_chart(pdk.Deck(layers=[layer], initial_view_state=view_state, tooltip=tooltip))

# --- Table ---
st.subheader(f"Rentals ({len(filtered)})")
st.dataframe(
    filtered[
        ["business_name", "business_type", "category", "license_status", "address"]
    ],
    width="stretch",
    hide_index=True,
)
