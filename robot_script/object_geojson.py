import json

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
                }
            } for obj in objects
        ]
    }

