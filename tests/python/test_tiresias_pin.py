"""The Tiresias pin must match in pyproject.toml (uv/local) and requirements.txt (Docker/Railway)."""

import re
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
# v0.1.2: settings/introspection function ban in the SQL guard + rejection text
# hidden in the public trace panel (on top of v0.1.1's CTE-scope fix).
EXPECTED_COMMIT = "6d5de45cec83cb1f912263be0f968c5f38d76d75"
ARCHIVE = f"https://github.com/EvanWAppel/tiresias/archive/{EXPECTED_COMMIT}.zip"


def test_pyproject_pins_tiresias_v0_1_2():
    pyproject = tomllib.loads((ROOT / "pyproject.toml").read_text())
    assert pyproject["tool"]["uv"]["sources"]["tiresias"]["url"] == ARCHIVE


def test_requirements_pins_same_archive():
    text = (ROOT / "requirements.txt").read_text()
    pins = re.findall(r"^tiresias\[streamlit\] @ (\S+)$", text, flags=re.MULTILINE)
    assert pins == [ARCHIVE]
