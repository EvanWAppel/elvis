"""Dark-theme contract: config, CSS tokens, and ui.py palette stay in sync and legible."""

import re
import tomllib
from pathlib import Path

import pytest

import ui

ROOT = Path(__file__).resolve().parents[2]


@pytest.fixture(scope="module")
def theme():
    return tomllib.loads((ROOT / ".streamlit" / "config.toml").read_text())["theme"]


@pytest.fixture(scope="module")
def css_tokens():
    css = (ROOT / "explorer.css").read_text()
    root = re.search(r":root\{([^}]*)\}", css)
    assert root, "explorer.css has no :root token block"
    return dict(re.findall(r"--elvis-([\w-]+):(#[0-9a-fA-F]{6})", root.group(1)))


def contrast(fg, bg):
    def luminance(hex_color):
        channels = [int(hex_color[i : i + 2], 16) / 255 for i in (1, 3, 5)]
        linear = [
            c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
            for c in channels
        ]
        return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]

    light, dark = sorted((luminance(fg), luminance(bg)), reverse=True)
    return (light + 0.05) / (dark + 0.05)


def test_streamlit_theme_is_dark_and_matches_css(theme, css_tokens):
    assert theme["base"] == "dark"
    assert theme["backgroundColor"] == css_tokens["paper"]
    assert theme["secondaryBackgroundColor"] == css_tokens["panel"]
    assert theme["textColor"] == css_tokens["ink"]
    assert theme["primaryColor"] == css_tokens["red"]


def test_ui_palette_matches_css_tokens(css_tokens):
    assert ui.PINK == css_tokens["red"]
    assert ui.CYAN == css_tokens["cyan"]
    assert ui.GOLD == css_tokens["gold"]
    assert ui.PURPLE == css_tokens["purple"]
    assert ui.MUTED == css_tokens["muted"]


# Text/surface pairings, deliberately a superset of what the CSS renders today
# (cyan/gold are accents now, but may carry text). `lift` (hover rows) only
# carries ink, muted and the pink hover state; the primary button is paper on red.
USED_PAIRS = [
    *[
        (fg, bg)
        for fg in ["ink", "muted", "red", "cyan", "gold"]
        for bg in ["paper", "panel"]
    ],
    ("ink", "lift"),
    ("muted", "lift"),
    ("red", "lift"),
    ("paper", "red"),
]


@pytest.mark.parametrize(("fg", "bg"), USED_PAIRS)
def test_text_tokens_meet_wcag_aa_on_dark_surfaces(css_tokens, fg, bg):
    assert contrast(css_tokens[fg], css_tokens[bg]) >= 4.5


@pytest.mark.parametrize("mark", [*ui.SERIES, ui.ORANGE])
def test_chart_marks_meet_wcag_aa_on_panel(css_tokens, mark):
    assert contrast(mark, css_tokens["panel"]) >= 4.5


def test_atlas_chart_uses_dark_panel_and_neon_series(monkeypatch, css_tokens):
    import altair as alt
    import pandas as pd

    captured = {}
    monkeypatch.setattr(
        ui.st, "altair_chart", lambda chart, **_: captured.setdefault("c", chart)
    )
    ui.atlas_chart(alt.Chart(pd.DataFrame({"x": [1]})).encode(x="x").mark_point())
    config = captured["c"].to_dict()["config"]
    assert config["background"] == css_tokens["panel"]
    assert config["axis"]["labelColor"] == css_tokens["ink"]
    assert config["axis"]["gridColor"] == css_tokens["line"]
    assert config["range"]["category"] == ui.SERIES
