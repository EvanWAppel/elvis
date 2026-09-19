"""Shared visual identity for the Elvis data explorer."""

from pathlib import Path

import streamlit as st


def apply_theme():
    """Load presentation styles without changing native widget behavior."""
    st.html(f"<style>{Path(__file__).with_name('explorer.css').read_text()}</style>")
    with st.sidebar:
        st.html(
            '<div class="elvis-brand">elvis<span>✳</span></div>'
            '<div class="elvis-caption">AN INDEPENDENT ATLAS<br>OF THE LAS VEGAS VALLEY</div>'
        )
        st.caption("Public data. A different perspective.")
