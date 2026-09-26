"""Shared visual identity for the Elvis data explorer."""

from pathlib import Path

import streamlit as st


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
        range={"category": ["#ff2e88", "#28e0d8", "#ffc247", "#8a4fff", "#5ac8fa", "#4be08a"]},
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
