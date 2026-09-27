"""Census-tract comparisons across the valley's available source footprints."""

from pathlib import Path

import streamlit as st

from tract_map import TOPIC_LABELS, render_tract_map

st.title("Compare Census Tracts")
st.caption(
    "Full-snapshot area comparisons across Las Vegas, North Las Vegas, Henderson, "
    "and existing county coverage. Individual places and road projects retain their own maps."
)
topic = st.selectbox("Topic", list(TOPIC_LABELS), format_func=lambda value: TOPIC_LABELS[value])
render_tract_map(topic, key=f"compare_{topic}")
with st.expander("Coverage by topic and city"):
    st.markdown(Path("docs/COVERAGE.md").read_text())
