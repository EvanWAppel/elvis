import streamlit as st
import pydeck as pdk
import pandas as pd
from snowflake.snowpark.context import get_active_session

st.set_page_config(page_title="Las Vegas Public Art", layout="wide")
st.title("City of Las Vegas Public Art Collection")

session = get_active_session()

df = session.sql("SELECT * FROM PC_DBT_DB.DBT_EAPPEL.MART_ART_WORK_POINTS").to_pandas()

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
        st.image(row["PIC_URL"], use_column_width=True)
with col2:
    st.markdown(f"**Artist:** {row['ARTIST']}")
    st.markdown(f"**Medium:** {row['MEDIUM']}")
    st.markdown(f"**Location:** {row['LOCATION_DETAIL']}")
    st.markdown(f"**Address:** {row['ADDRESS']}")
    st.markdown(f"**Ward:** {row['WARD']}")
