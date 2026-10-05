"""Ask Tiresias: the grounded text-to-SQL chat over every Elvis dataset.

The engine, prompts, SQL guard and abuse guards live in the pinned ``tiresias``
library; this page only points it at Elvis's ``tiresias.yml``. Caps can be tuned
with the ``TIRESIAS_MAX_*`` Railway variables.
"""

from pathlib import Path

from tiresias.chat import render_chat
from tiresias.config import load_config

render_chat(load_config(Path(__file__).resolve().parents[1] / "tiresias.yml"))
