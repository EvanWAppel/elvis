"""Shared, deterministic tract map encoding; color domains precede city filters."""

import json
import math

import pandas as pd

RAMP = [(152, 102, 255), (255, 46, 136), (255, 122, 26), (255, 194, 71)]
NO_DATA = [85, 85, 98, 120]


def value_color(value, maximum: float) -> list[int]:
    if value is None or pd.isna(value):
        return NO_DATA.copy()
    position = (
        min(1.0, max(0.0, float(value) / maximum)) * (len(RAMP) - 1) if maximum else 0
    )
    low = min(int(position), len(RAMP) - 2)
    fraction = position - low
    return [round(a + (b - a) * fraction) for a, b in zip(RAMP[low], RAMP[low + 1])] + [
        195
    ]


def map_features(rows: pd.DataFrame, metric: str, cities: list[str]):
    maximum = float(rows[metric].max()) if not rows.empty else 0.0
    if not math.isfinite(maximum):
        maximum = 0.0
    features = []
    for row in rows.to_dict("records"):
        if not set(json.loads(row["cities_json"])) & set(cities):
            continue
        value = row[metric]
        label = (
            "No data"
            if pd.isna(value)
            else f"{value:,.1f}"
            if metric == "rate_per_1000"
            else f"{value:,.0f}"
        )
        features.append(
            {
                "type": "Feature",
                "geometry": json.loads(row["geometry_json"]),
                "properties": {
                    "geoid": row["geoid"],
                    "tract_name": row["tract_name"],
                    "cities": ", ".join(json.loads(row["cities_json"])),
                    "value_label": label,
                    "coverage": row["coverage"],
                    "period": row["period"],
                    "boundary_vintage": row["boundary_vintage"],
                    "population_label": "Unavailable"
                    if pd.isna(row["population"])
                    else f"{row['population']:,.0f}",
                    "fill": value_color(value, maximum),
                },
            }
        )
    return features, maximum
