import geocoder
g = geocoder.ip('me')
print("OK:", g.ok)
print("\n ######################\n:" )
print("LatLng:", g.latlng)

