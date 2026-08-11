"""Short-term rentals across the Las Vegas metro — map and roster."""

import pydeck as pdk
import streamlit as st

from app_db import query

st.title("🏠 Short-Term Rentals")
st.caption(
    "Licensed / registered short-term rentals (Airbnb-style) across the metro: "
    "City of Las Vegas, North Las Vegas, and Henderson."
)

df = query(
    """
    select jurisdiction, business_name, status, category, address,
           issued_date, latitude, longitude
    from main.mart_short_term_rentals
    """
)

# --- Sidebar filters ---
st.sidebar.header("Filters")
jurisdictions = sorted(df["jurisdiction"].unique())
sel_j = st.sidebar.multiselect("Jurisdiction", jurisdictions, default=jurisdictions)
statuses = sorted(df["status"].dropna().unique())
sel_s = st.sidebar.multiselect("Status", statuses, default=statuses)

filtered = df[df["jurisdiction"].isin(sel_j) & df["status"].isin(sel_s)]

c1, c2, c3 = st.columns(3)
c1.metric("Rentals", f"{len(filtered):,}")
c2.metric("Active", f"{(filtered['status'].str.lower() == 'active').sum():,}")
c3.metric("Jurisdictions", f"{filtered['jurisdiction'].nunique()}")

if filtered.empty:
    st.info("No rentals match the current filters.")
    st.stop()

# --- Map, colored by jurisdiction ---
palette = {
    "Las Vegas": [230, 69, 46, 180],
    "North Las Vegas": [32, 128, 128, 180],
    "Henderson": [106, 76, 147, 180],
}
filtered = filtered.copy()
filtered["fill"] = filtered["jurisdiction"].apply(lambda j: palette.get(j, [120, 120, 120, 160]))
layer = pdk.Layer(
    "ScatterplotLayer",
    data=filtered,
    get_position=["longitude", "latitude"],
    get_radius=90,
    get_fill_color="fill",
    pickable=True,
)
view_state = pdk.ViewState(
    latitude=filtered["latitude"].mean(),
    longitude=filtered["longitude"].mean(),
    zoom=9.5,
    pitch=0,
)
tooltip = {
    "html": "<b>{business_name}</b><br/>{jurisdiction}<br/>{address}<br/>{category}<br/>{status}",
    "style": {"backgroundColor": "steelblue", "color": "white", "fontSize": "13px"},
}
st.pydeck_chart(
    pdk.Deck(
        layers=[layer],
        initial_view_state=view_state,
        map_style="https://basemaps.cartocdn.com/gl/positron-gl-style/style.json",
        tooltip=tooltip,
    )
)
st.caption("🔴 Las Vegas · 🟢 North Las Vegas · 🟣 Henderson")

# --- Table ---
st.subheader(f"Rentals ({len(filtered)})")
st.dataframe(
    filtered[["business_name", "jurisdiction", "status", "category", "address", "issued_date"]],
    width="stretch",
    hide_index=True,
)
