"""Shared visual identity for the Elvis data explorer."""

from pathlib import Path

import streamlit as st


def atlas_chart(chart, **kwargs):
    """Render charts in the atlas palette, independent of session theme."""
    chart = chart.configure(
        background="#eeece4",
        font="DM Sans",
        view={"stroke": None},
        axis={
            "labelColor": "#232820",
            "titleColor": "#232820",
            "gridColor": "#d4d4c8",
            "domainColor": "#8c927e",
            "tickColor": "#8c927e",
            "labelFontSize": 12,
            "titleFontSize": 12,
        },
        legend={"labelColor": "#232820", "titleColor": "#232820", "labelFontSize": 12},
        title={"color": "#232820"},
        range={"category": ["#bd3c24", "#326b82", "#536b3f", "#80629a", "#976b20", "#427d75"]},
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
