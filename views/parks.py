"""Parks across the Las Vegas metro — mapped, with water-feature flags."""

import pydeck as pdk
import streamlit as st

from app_db import query

st.title("🌳 Metro Parks")
st.caption(
    "Parks across the Las Vegas metro — City of Las Vegas, Henderson, "
    "unincorporated Clark County, and North Las Vegas — flagged by whether they "
    "contain a water feature (pool, splash pad, or lake/pond)."
)

df = query(
    """
    select jurisdiction, park_name, address, acres, has_water, latitude, longitude
    from main.mart_parks
    """
)


def water_label(v):
    if v is True:
        return "💧 Water feature"
    if v is False:
        return "No water feature"
    return "Unknown"


df["water"] = df["has_water"].apply(water_label)

# --- Sidebar filters ---
st.sidebar.header("Filters")
jurisdictions = sorted(df["jurisdiction"].unique())
selected = st.sidebar.multiselect("Jurisdiction", jurisdictions, default=jurisdictions)
water_only = st.sidebar.checkbox("Only parks with a water feature", value=False)

filtered = df[df["jurisdiction"].isin(selected)]
if water_only:
    filtered = filtered[filtered["has_water"] == True]

c1, c2, c3 = st.columns(3)
c1.metric("Parks", f"{len(filtered):,}")
c2.metric("With a water feature", f"{int((filtered['has_water'] == True).sum()):,}")
known_acres = filtered["acres"].dropna()
c3.metric("Total acreage (where known)", f"{known_acres.sum():,.0f}")

if filtered.empty:
    st.info("No parks match the current filters.")
    st.stop()

# --- Map: blue = water feature, green = none, gray = unknown ---
colors = {True: [28, 126, 214, 200], False: [46, 139, 87, 160]}
filtered = filtered.copy()
filtered["fill"] = filtered["has_water"].apply(lambda v: colors.get(v, [150, 150, 150, 140]))
filtered["radius"] = (filtered["acres"].fillna(4).clip(lower=1) ** 0.5) * 22
layer = pdk.Layer(
    "ScatterplotLayer",
    data=filtered,
    get_position=["longitude", "latitude"],
    get_radius="radius",
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
    "html": "<b>{park_name}</b><br/>{jurisdiction}<br/>{address}<br/>{water}",
    "style": {"backgroundColor": "seagreen", "color": "white", "fontSize": "13px"},
}
st.pydeck_chart(
    pdk.Deck(
        layers=[layer],
        initial_view_state=view_state,
        map_style="https://basemaps.cartocdn.com/gl/positron-gl-style/style.json",
        tooltip=tooltip,
    )
)
st.caption("🔵 has a water feature · 🟢 none · ⚪ unknown (Clark County / North Las Vegas publish no water data)")

# --- Table ---
st.subheader(f"Parks ({len(filtered)})")
st.dataframe(
    filtered[["park_name", "jurisdiction", "address", "acres", "water"]]
    .sort_values(["jurisdiction", "park_name"]),
    width="stretch",
    hide_index=True,
)
