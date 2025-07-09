import 'package:latlong2/latlong.dart';

class Markers{
  final List<Map<String, dynamic>> markersData = [
    {
      'label': 'ROBOT',
      'location': LatLng(36.8065, 10.1815), // Tunis center
    },
    {
      'label': 'DOG',
      'location': LatLng(36.8100, 10.1900), // Nearby
    },
    {
      'label': 'CAR',
      'location': LatLng(36.8000, 10.1700), // Nearby
    },
  ];
}