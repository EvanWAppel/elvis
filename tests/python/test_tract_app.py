import pandas as pd
from streamlit.testing.v1 import AppTest


def test_tract_controls_render_rates_and_empty_selection(monkeypatch, map_rows):
    import tract_map

    map_rows["topic"] = "calls"
    audit = pd.DataFrame(
        [
            {
                "topic": "calls",
                "assigned_records": 110,
                "source_records": 112,
                "invalid_coordinates": 1,
                "outside_tracts": 1,
                "boundary_ties": 0,
            }
        ]
    )

    def query(sql):
        if "assignment_audit" in sql:
            return audit
        return map_rows

    monkeypatch.setattr(tract_map, "query", query)

    def app():
        from tract_map import render_tract_map

        render_tract_map("calls", key="test_tracts")

    at = AppTest.from_function(app).run()
    assert not at.exception
    assert at.radio[0].value == "Count"
    at.radio[0].set_value("Per 1,000 residents (2020 Census)").run()
    assert not at.exception
    at.multiselect[0].set_value([]).run()
    assert not at.exception
    assert any("Select at least one" in item.value for item in at.info)


def test_hidden_tract_selection_does_not_show_stale_details(monkeypatch, map_rows):
    import tract_map

    map_rows["topic"] = "calls"

    def query(sql):
        assert "stg_tract_counts" not in sql, "Hidden selection requested a breakdown"
        if "assignment_audit" in sql:
            return pd.DataFrame(columns=["topic"])
        return map_rows

    monkeypatch.setattr(tract_map, "query", query)
    monkeypatch.setattr(
        tract_map.st,
        "pydeck_chart",
        lambda *a, **k: {
            "selection": {"objects": {"tracts": [{"properties": {"geoid": "b"}}]}}
        },
    )

    def app():
        import streamlit as st

        from tract_map import render_tract_map

        st.session_state["test_hidden_cities"] = ["Las Vegas"]
        render_tract_map("calls", key="test_hidden")

    at = AppTest.from_function(app).run()
    assert not at.exception
