"""The Tiresias pin must match in pyproject.toml (uv/local) and requirements.txt (Docker/Railway)."""

import re
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
# v0.1.1: CTE-scope allowlist bypass fix + locked-down DuckDB connection.
EXPECTED_COMMIT = "0ae91238f19070d6453762dee831d110d0f2e5f9"
ARCHIVE = f"https://github.com/EvanWAppel/tiresias/archive/{EXPECTED_COMMIT}.zip"


def test_pyproject_pins_tiresias_v0_1_1():
    pyproject = tomllib.loads((ROOT / "pyproject.toml").read_text())
    assert pyproject["tool"]["uv"]["sources"]["tiresias"]["url"] == ARCHIVE


def test_requirements_pins_same_archive():
    text = (ROOT / "requirements.txt").read_text()
    pins = re.findall(r"^tiresias\[streamlit\] @ (\S+)$", text, flags=re.MULTILINE)
    assert pins == [ARCHIVE]
