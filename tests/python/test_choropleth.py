from choropleth import map_features, value_color


def test_city_filter_keeps_shared_scale(map_rows):
    full, maximum = map_features(map_rows, "record_count", ["Las Vegas", "Henderson"])
    filtered, filtered_maximum = map_features(map_rows, "record_count", ["Las Vegas"])
    assert maximum == filtered_maximum == 100
    assert full[0]["properties"]["fill"] == filtered[0]["properties"]["fill"]
    assert len(filtered) == 1


def test_missing_values_differ_from_observed_zero():
    assert value_color(None, 100) != value_color(0, 100)


def test_empty_selection_and_rate_missingness(map_rows):
    assert map_features(map_rows, "record_count", [])[0] == []
    features, maximum = map_features(map_rows, "rate_per_1000", ["Henderson"])
    assert maximum == 1000
    assert features[1]["properties"]["value_label"] == "No data"
