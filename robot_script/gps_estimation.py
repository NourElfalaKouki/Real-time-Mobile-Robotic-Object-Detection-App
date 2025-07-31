from geopy.distance import distance as geodistance
from geopy import Point

def estimate_gps(current_lat, current_lon, distance_meters, angle_degrees):
    point = Point(current_lat, current_lon)
    destination = geodistance(meters=distance_meters).destination(point, angle_degrees)
    return destination.latitude, destination.longitude
