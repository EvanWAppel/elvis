"""Shared visual identity for the Elvis data explorer."""

from pathlib import Path

import streamlit as st

# Neon-night palette — mirrors the explorer.css tokens so charts and maps match
# the chrome. Import these into views instead of hardcoding hex/RGB.
PINK = "#ff2e88"
CYAN = "#28e0d8"
GOLD = "#ffc247"
PURPLE = "#8a4fff"
BLUE = "#5ac8fa"
GREEN = "#4be08a"
ORANGE = "#ff7a1a"
MUTED = "#a9a3c9"

# Categorical range (also used by atlas_chart) and a dark-safe sequential
# ("neon heat") ramp for quantitative color scales.
SERIES = [PINK, CYAN, GOLD, PURPLE, BLUE, GREEN]
SEQUENTIAL = [CYAN, PURPLE, PINK, GOLD]

# Dark basemap for every PyDeck map (was Carto positron / light).
MAP_STYLE = "https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json"


def atlas_chart(chart, **kwargs):
    """Render charts in the atlas palette, independent of session theme."""
    chart = chart.configure(
        background="#16141f",
        font="DM Sans",
        view={"stroke": None},
        axis={
            "labelColor": "#f4f1e9",
            "titleColor": "#f4f1e9",
            "gridColor": "#2a2740",
            "domainColor": "#4a4668",
            "tickColor": "#4a4668",
            "labelFontSize": 12,
            "titleFontSize": 12,
        },
        legend={"labelColor": "#f4f1e9", "titleColor": "#f4f1e9", "labelFontSize": 12},
        title={"color": "#f4f1e9"},
        range={"category": SERIES},
    )
    return st.altair_chart(chart, theme=None, **kwargs)


def apply_theme():
    """Load presentation styles without changing native widget behavior."""
    st.html(f"<style>{Path(__file__).with_name('explorer.css').read_text()}</style>")
    with st.sidebar:
        st.html(
            '<div class="elvis-brand">elvis<span>✳</span></div>'
            '<div class="elvis-caption">AN INDEPENDENT ATLAS<br>OF THE LAS VEGAS VALLEY</div>'
        )
        st.caption("Public data. A different perspective.")
