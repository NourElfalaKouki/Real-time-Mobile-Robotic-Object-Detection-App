
def create_geojson(objects):
    return {
        "type": "FeatureCollection",
        "features": [
            {
                "type": "Feature",
                "geometry": {
                    "type": "Point",
                    "coordinates": [obj["lon"], obj["lat"]],
                },
                "properties": {
                    "label": obj["label"],
                    "timestamp": obj["timestamp"] if "timestamp" in obj else None,
                }
            } for obj in objects
        ]
    }

