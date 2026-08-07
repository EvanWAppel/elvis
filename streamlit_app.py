"""Las Vegas public-art map — the interactive demo behind the portfolio landing page.

In Snowflake this app read the MART_ART_WORK_POINTS table live via
get_active_session(). For the public portfolio deploy (Streamlit Community
Cloud) there is no Snowflake connection, so it reads a committed snapshot of
that same mart, rebuilt from the public source by build_snapshot.py.
"""

from pathlib import Path

import pandas as pd
import pydeck as pdk
import streamlit as st

st.set_page_config(page_title="Las Vegas Public Art", layout="wide")
st.title("City of Las Vegas Public Art Collection")

DATA_PATH = Path(__file__).parent / "app_data" / "mart_art_work_points.csv"


@st.cache_data
def load_data() -> pd.DataFrame:
    """Load the mart snapshot (mirrors the Snowflake MART_ART_WORK_POINTS table)."""
    return pd.read_csv(DATA_PATH)


df = load_data()

# --- Sidebar filters ---
st.sidebar.header("Filters")
wards = sorted(df["WARD"].dropna().unique())
selected_wards = st.sidebar.multiselect("Ward", wards, default=wards)

filtered = df[df["WARD"].isin(selected_wards)]

# --- Map ---
layer = pdk.Layer(
    "ScatterplotLayer",
    data=filtered,
    get_position=["LONGITUDE", "LATITUDE"],
    get_radius=50,
    get_fill_color=[255, 100, 0, 180],
    pickable=True,
)

view_state = pdk.ViewState(
    latitude=filtered["LATITUDE"].mean(),
    longitude=filtered["LONGITUDE"].mean(),
    zoom=12,
    pitch=0,
)

tooltip = {
    "html": "<b>{ARTWORK_NAME}</b><br/>{ARTIST}<br/><i>{MEDIUM}</i><br/>{ADDRESS}",
    "style": {"backgroundColor": "steelblue", "color": "white", "fontSize": "13px"},
}

st.pydeck_chart(pdk.Deck(layers=[layer], initial_view_state=view_state, tooltip=tooltip))

# --- Selected artwork detail panel ---
st.subheader(f"Artworks ({len(filtered)})")
selected = st.selectbox("Select an artwork to preview", filtered["ARTWORK_NAME"].sort_values())

row = filtered[filtered["ARTWORK_NAME"] == selected].iloc[0]
col1, col2 = st.columns([1, 2])
with col1:
    if pd.notna(row["PIC_URL"]):
        st.image(row["PIC_URL"], use_container_width=True)
with col2:
    st.markdown(f"**Artist:** {row['ARTIST']}")
    st.markdown(f"**Medium:** {row['MEDIUM']}")
    st.markdown(f"**Location:** {row['LOCATION_DETAIL']}")
    st.markdown(f"**Address:** {row['ADDRESS']}")
    st.markdown(f"**Ward:** {row['WARD']}")
